# vim:fileencoding=utf-8
require 'logger'
require 'rubygems'
require 'bundler'
Bundler.setup(:processor)

require 'yajl'
require 'mq'
require 'configatron'
require 'notifo'

require 'ohm'
Ohm.connect
require_relative '../model/user'

require_relative '../model/message'

class Notifier
  def initialize(logger)
    configatron.configure_from_yaml(File.expand_path('../../config/config.yml',__FILE__))
    raise "Add config/config.yml" if configatron.nil?
    @logger = logger
    @notifo = Notifo.new(configatron.notifo.username,configatron.notifo.secret)
  end

  def notify(user,text,title,link)
    @logger.info "NOTIFY | %15s | to %15s | %10s | %s" % [user.twitter_screen_name,user.notifo_username,'Sending',text]
    EM.defer(proc{
      begin
        result = @notifo.post(user.notifo_username,text,title,link)
        if result['response_message'] == 'OK'
          @logger.info "NOTIFY | %15s | to %15s | %10s | %s" % [user.twitter_screen_name,user.notifo_username,'OK',text]
        else
          @logger.warn "NOTIFY | %15s | to %15s | %10s | %s" % [user.twitter_screen_name,user.notifo_username,result['response_message'],text]
        end
      rescue
        @logger.error "NOTIFY | %15s | to %15s | %10s | %s" % [user.twitter_screen_name,user.notifo_username,$!,text]
      end
    })
  end

  def filter(user,message)
    type = Message.type(message)
    @logger.info "%15s | %15s | %s" % [user.twitter_screen_name,type,message['id']||message['created_at']]

    case type
    when Message::TWEET
      if message['in_reply_to_user_id'].to_s == user.twitter_id || message['entities']['user_mentions'].any?{|item| item['id_str'] == user.twitter_id}
        text = "@#{message['user']['screen_name']}: #{message['text']}"
        link = "http://twitter.com/#{message['user']['screen_name']}/status/#{message['id']}"
        title = "@#{user.twitter_screen_name}"
        notify(user,text,title,link)
      end
    when Message::RETWEET
      if message['retweeted_status']['user']['id'].to_s == user.twitter_id
        text = "@#{message['user']['screen_name']}: #{message['text']}"
        link = "http://twitter.com/#{message['user']['screen_name']}/status/#{message['id']}"
        title = "retweeted"
        notify(user,text,title,link)
      end
    when Message::FAVORITE
      if message['target']['id'].to_s == user.twitter_id
        text = "@#{message['source']['screen_name']}: #{message['target_object']['text']}"
        link = "http://twitter.com/#{message['source']['screen_name']}/favorites"
        title = "favorited"
        notify(user,text,title,link)
      end
    when Message::UNFAVORITE
      if message['target']['id'].to_s == user.twitter_id
        text = "@#{message['source']['screen_name']}: #{message['target_object']['text']}"
        link = "http://twitter.com/#{message['source']['screen_name']}"
        title = "unfavorited"
        notify(user,text,title,link)
      end
    when Message::FOLLOW
      if message['target']['id'].to_s == user.twitter_id
        text = "@#{message['source']['screen_name']} (#{message['source']['name']}) is now following you"
        link = "http://twitter.com/#{message['source']['screen_name']}"
        title = "followed"
        notify(user,text,title,link)
      end
    when Message::LIST_MEMBER_ADDED
      if message['target']['id'].to_s == user.twitter_id
        text = "You have been added to @#{message['source']['screen_name']}'s list: #{message['target_object']['slug']}"
        link = "http://twitter.com#{message['target_object']['uri']}"
        title = "list member added"
        notify(user,text,title,link)
      end
    when Message::LIST_MEMBER_REMOVED
      if message['target']['id'].to_s == user.twitter_id
        text = "You have been removed from @#{message['source']['screen_name']}'s list: #{message['target_object']['slug']}"
        link = "http://twitter.com#{message['target_object']['uri']}"
        title = "list member removed"
        notify(user,text,title,link)
      end
    when Message::DIRECT_MESSAGE
      if message['direct_message']['recipient_id'].to_s == user.twitter_id
        text = "@#{message['direct_message']['sender']['screen_name']} sent you a message. Check it now!"
        link = "http://twitter.com/messages"
        title = "direct message"
        notify(user,text,title,link)
      end
    end
  end

  def start
    parser = Yajl::Parser
    @logger.info "Start notifier"
    AMQP.start do
      MQ.queue('notwife').subscribe do |msg|
        begin
          data = parser.parse(msg)
          user = User.find(:twitter_id => data['for_user']).first
          if user and message = data['message']
            filter(user,message)
          else
            @logger.error "Invalid user or data: %s, %s, %s" % [user.twitter_id, user.twitter_screen_name,msg]
          end
        rescue
          @logger.error "Invalid message %s, %s" % [msg,$!]
        end
      end
      trap("TERM") {
        @logger.warn "Finish"
        EM.stop
      }
      trap("INT")  {
        @logger.warn "Finish"
        EM.stop
      }
    end
  end
end

logger = Logger.new(ARGV[0]||STDOUT,'daily')
notifier = Notifier.new(logger)
notifier.start
