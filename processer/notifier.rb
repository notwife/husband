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
    configatron.configure_from_yaml(File.dirname(__FILE__)+'/config.yml')
    raise "Add processer/config.yml" if configatron.nil?
    @notifo = Notifo.new(configatron.notifo.username,configatron.notifo.api_secret)
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
    when Message::FAVORITE
      if message['source']['id'].to_s != user.twitter_id
        text = "@#{message['source']['screen_name']}: #{message['target_object']['text']}"
        link = "http://twitter.com/#{message['source']['screen_name']}/favorites"
        title = "favorited"
        p text
        p @notifo.post(user.notifo_username,text,title,link)
      end
    else
      p message['created_at']
    end
  end

  def start
    parser = Yajl::Parser
    AMQP.start do
      MQ.queue('notwife').subscribe do |msg|
        data = parser.parse(msg)
        user = User.find(:twitter_id => data['for_user']).first
        if user and message = data['message']
          puts "#{user.twitter_name} | #{Message.type(message)} | #{message['id']||message['created_at']}"
          notify(user,message)
        end
      end
    end
  end
end

notifier = Notifier.new
notifier.start
