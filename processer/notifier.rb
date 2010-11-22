# vim:fileencoding=utf-8
require 'rubygems'
require 'bundler'
Bundler.setup(:redis,:amqp,:notifo)

require 'yajl'
require 'mq'
require 'configatron'
require 'notifo'

require 'ohm'
Ohm.connect
require_relative '../model/user'

require_relative '../model/message'

class Notifier
  def initialize
    configatron.configure_from_yaml(File.dirname(__FILE__)+'/../config/config.yml')
    raise "Add config/config.yml" if configatron.nil?
    @notifo = Notifo.new(configatron.notifo.username,configatron.notifo.secret)
  end

  def notify(user,message)
    case Message.type(message)
    when Message::TWEET
      if message['in_reply_to_user_id_str'] == user.twitter_id || message['entities']['user_mentions'].any?{|item| item['id_str'] == user.twitter_id}
        text = "@#{message['user']['screen_name']}: #{message['text']}"
        link = "http://twitter.com/#{message['user']['screen_name']}/status/#{message['id']}"
        title = "@#{user.twitter_screen_name}"
        p text
        p @notifo.post(user.notifo_username,text,title,link)
      end
    when Message::RETWEET
      if message['retweeted_status']['user']['id'].to_s == user.twitter_id
        text = "#{message['user']['screen_name']}: #{message['text']}"
        link = "http://twitter.com/#{message['user']['screen_name']}/status/#{message['id']}"
        title = "retweeted"
        p text
        p @notifo.post(user.notifo_username,text,title,link)
      end
    when Message::FAVORITE
      if message['source']['id'].to_s != user.twitter_id
        text = "@#{message['source']['screen_name']}: #{message['target_object']['text']}"
        link = "http://twitter.com/#{message['source']['screen_name']}/favorites"
        title = "favorited"
        p text
        p @notifo.post(user.notifo_username,text,title,link)
      end
    when Message::FOLLOW
      if message['target']['id'].to_s == user.twitter_id
        text = "@#{message['source']['screen_name']} (#{message['source']['name']}) is now following you"
        link = "http://twitter.com/#{message['source']['screen_name']}"
        title = "follow"
        p text
        p @notifo.post(user.notifo_username,text,title,link)
      end
    when Message::LIST_MEMBER_ADDED
      if message['target']['id'].to_s == user.twitter_id
        text = "You have been added to @#{message['source']['screen_name']}'s list: #{message['target_object']['slug']}"
        link = "http://twitter.com#{message['target_object']['uri']}"
        title = "list member added"
        p text
        p @notifo.post(user.notifo_username,text,title,link)
      end
    when Message::DIRECT_MESSAGE
      if message['direct_message']['recipient_id'].to_s == user.twitter_id
        text = "@#{message['direct_message']['sender']['screen_name']} sent you a message. Check it now!"
        link = "http://mobile.twitter.com/inbox"
        title = "direct message"
        p text
        p @notifo.post(user.notifo_username,text,title,link)
      end
    else
      require 'pp'
      pp message
    end
  end

  def start
    parser = Yajl::Parser
    AMQP.start do
      MQ.queue('notwife').subscribe do |msg|
        data = parser.parse(msg)
        user = User.find(:twitter_id => data['for_user']).first
        if user and message = data['message']
          puts "%10s | %10s | %s" % [user.twitter_screen_name,Message.type(message),message['id']||message['created_at']]
          notify(user,message)
        end
      end
    end
  end
end

notifier = Notifier.new
notifier.start
