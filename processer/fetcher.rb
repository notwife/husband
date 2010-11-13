# vim:fileencoding=utf-8
require 'rubygems'
require 'bundler'
Bundler.setup(:streams,:amqp)

require 'configatron'
require 'json'
require 'em-http'
require 'oauth'
require 'oauth/client/em_http'
require 'yajl'
require 'mq'

def createParser
  parser = Yajl::Parser.new
  encoder = Yajl::Encoder.new
  stream = MQ.new.fanout('stream')
  parser.on_parse_complete = Proc.new {|data|
    puts "fetched: #{Time.now}"
    stream.publish(encoder.encode(data).force_encoding('us-ascii'))
  }
  parser
end

def start
  follows = %w(3814821 4923231)
  oauth_consumer = OAuth::Consumer.new(configatron.twitter.consumer_key,configatron.twitter.consumer_secret,:site => 'http://twitter.com')
  oauth_access_token = OAuth::AccessToken.new(oauth_consumer,configatron.twitter.access_token,configatron.twitter.access_token_secret)

  EM.run do
    parser = createParser
    request = EventMachine::HttpRequest.new("https://betastream.twitter.com/2b/site.json")
    http = request.get(:query => {"follow" => follows.join(","), "with" => "followings"},
                       :head => {"Content-Type" => "application/x-www-form-urlencoded"},
                       :timeout => 90) do |client|
      oauth_consumer.sign!(client,oauth_access_token)
                       end

    puts "Start: #{Time.now}"
    http.stream do |chunk|
      if chunk == "\n"
        puts "#{Time.now} keep-alive"
      else
        parser << chunk
      end
    end

    http.callback do
      puts "fin"
      EM.stop
    end
    http.errback do
      puts "err"
      EM.stop
    end
  end
end

configatron.configure_from_yaml("config.yml")
raise "Add processer/config.yml" if configatron.nil?
start
