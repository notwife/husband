# vim:fileencoding=utf-8
require 'rubygems'
require 'bundler'
Bundler.setup(:processer)

require 'configatron'
require 'json'
require 'rubygems'
require 'em-http'
require 'oauth'
require 'oauth/client/em_http'
require 'yajl'

def createParser
  parser = Yajl::Parser.new
  parser.on_parse_complete = Proc.new {|data|
    p data
  }
  parser
end

def start(parser)
  follows = %w(3814821 4923231)
  oauth_consumer = OAuth::Consumer.new(configatron.consumer_key,configatron.consumer_secret,:site => 'http://twitter.com')
  oauth_access_token = OAuth::AccessToken.new(oauth_consumer,configatron.access_token,configatron.access_token_secret)

  EM.run do
    request = EventMachine::HttpRequest.new("https://betastream.twitter.com/2b/site.json")
    http = request.get(:query => {"follow" => follows.join(","), "with" => "followings"},
                       :head => {"Content-Type" => "application/x-www-form-urlencoded"}) do |client|
      oauth_consumer.sign!(client,oauth_access_token)
                       end

    puts "Start: #{Time.now}"
    http.stream do |chunk|
      parser << chunk
    end
  end
end

configatron.configure_from_yaml("config.yml")
raise "Add processer/config.yml" if configatron.nil?
parser = createParser
start(parser)
