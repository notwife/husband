# vim:fileencoding=utf-8
require 'rubygems'
require 'bundler'
Bundler.setup(:streams,:redis,:amqp)

require 'configatron'
require 'json'
require 'em-http'
require 'oauth'
require 'oauth/client/em_http'
require 'yajl'
require 'mq'

require 'ohm'
Ohm.connect
require_relative '../model/user'

def stream_parser(id)
  parser = Yajl::Parser.new
  encoder = Yajl::Encoder.new
  stream = MQ.new.fanout('stream')
  parser.on_parse_complete = Proc.new {|data|
    puts "#{id} fetched: #{Time.now} | #{data['for_user']}"
    stream.publish(encoder.encode(data).force_encoding('us-ascii'))
  }
  parser
end

def stream_request(id,follows,oauth_consumer,oauth_access_token)
  parser = stream_parser(id)
  request = EventMachine::HttpRequest.new("https://betastream.twitter.com/2b/site.json")
  http = request.get(:query => {"follow" => follows.join(","), "with" => "followings"},
                     :head => {"Content-Type" => "application/x-www-form-urlencoded"},
                     :timeout => 90) do |client|
    oauth_consumer.sign!(client,oauth_access_token)
                     end
  # Start
  puts "#{id} Start: #{Time.now}"
  p follows
  http.stream do |chunk|
    if chunk == "\n"
      puts "#{Time.now} keep-alive"
    else
      parser << chunk
    end
  end
  # finish
  http.callback do
    puts "#{id} Finished: #{Time.now}"
  end
  http.errback do
    puts "#{id} Finished: #{Time.now}"
  end
  http
end

def follows
  User.all.map do |user|
    user.twitter_id
  end
end

def start
  oauth_consumer = OAuth::Consumer.new(configatron.twitter.consumer_key,configatron.twitter.consumer_secret,:site => 'http://twitter.com')
  oauth_access_token = OAuth::AccessToken.new(oauth_consumer,configatron.twitter.access_token,configatron.twitter.access_token_secret)

  EM.run do
    http = nil
    operation_queue = MQ.queue('operation')

    id = 0
    operation_queue.subscribe do |msg|
      puts "Received: #{msg}"
      case msg
      when "start", "reload"
        id += 1
        http.close_connection if http
        http = stream_request(id,follows,oauth_consumer,oauth_access_token)
      when "stop"
        EM.stop
      else
        puts "Undefined: #{msg}"
      end
    end

    operation_queue.publish("start")
  end
end

configatron.configure_from_yaml(File.dirname(__FILE__)+"/config.yml")
raise "Add processer/config.yml" if configatron.nil?
start
