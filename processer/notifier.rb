# vim:fileencoding=utf-8
require 'rubygems'
require 'bundler'
Bundler.setup(:redis,:amqp,:notifo)

require 'yajl'
require 'mq'
require 'ohm'
require 'configatron'
require 'notifo'

Ohm.connect
require_relative '../model/user'

class Notifier
  class Message
    [:tweet,:retweet,
      :list_member_added,:list_member_removed,
      :follow,:favorite,:unfavorite,
      :list_created,:list_updated,:list_destroyed,
      :friends,:delete,:direct_message
    ].each do |type|
      self.const_set(type.upcase,type)
    end

    def self.type(message)
      if message['text']
        if message['retweeted_status']
          return self::RETWEET
        else
          return self::TWEET
        end
      elsif message['event']
        case message['event']
        when 'list_member_added'
          return self::LIST_MEMBER_ADDED
        when 'list_member_removed'
          return self::LIST_MEMBER_REMOVED
        when 'follow'
          return self::FOLLOW
        when 'favorite'
          return self::FAVORITE
        when 'unfavorite'
          return self::UNFAVORITE
        when 'list_created'
          return self::LIST_CREATED
        when 'list_updated'
          return self::LIST_UPDATED
        when 'list_destroyed'
          return self::LIST_DESTROYED
        end
      elsif message['friends']
        return self::FRIENDS
      elsif message['delete']
        return self::DELETE
      elsif message['direct_message']
        return self::DIRECT_MESSAGE
      else
        return :unknown
      end
    end
  end
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
        title = "@#{user.twitter_name}"
        p text
        p @notifo.post(user.notifo_name,text,title,link)
      end
    when Message::FAVORITE
      if message['source']['id'].to_s != user.twitter_id
        text = "@#{message['source']['screen_name']}: #{message['target_object']['text']}"
        link = "http://twitter.com/#{message['source']['screen_name']}/favorites"
        title = "favorited"
        p text
        p @notifo.post(user.notifo_name,text,title,link)
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
          notify(user,message)
        end
      end
    end
  end
end

notifier = Notifier.new
notifier.start
