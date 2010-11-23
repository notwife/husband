# vim:fileencoding=utf-8
require 'logger'
require 'set'
require 'rubygems'
require 'bundler'
Bundler.setup(:processor)

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

require_relative '../model/message'

class Fetcher
  def initialize(logger)
    configatron.configure_from_yaml(File.expand_path('../../config/config.yml',__FILE__))
    raise "Add config/config.yml" if configatron.nil?
    @logger = logger
    @reloading = false
    @duplicate = false
    @id_set = Set.new
  end

  def stream_parser(id)
    parser = Yajl::Parser.new
    encoder = Yajl::Encoder.new
    stream = MQ.new.fanout('stream')
    parser.on_parse_complete = Proc.new {|data|
      type = Message.type(data['message'])
      @logger.info "STREAM %2s | fetched | %10s | %-10s | %s" % [id,data['for_user'],type,data['message']['id'] || data['message']['created_at']]
      if @reloading && type != Message::FRIENDS
        duplicate = !@id_set.add?([data['for_user'], type,
                                  data['message']['id'] || data['message']['created_at'] ].join)
        @duplicate = duplicate
        @logger.warn "STREAM %2s | reloading | duplicate? %-5s | %10s | %-10s | %s" % [id,duplicate,data['for_user'],type,data['message']['id'] || data['message']['created_at']]
      end
      unless @reloading && duplicate
        stream.publish(encoder.encode(data).force_encoding('us-ascii'))
      end
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
    @logger.info "STREAM %2s | Start | %s" % [id,follows]
    http.stream do |chunk|
      if chunk == "\n"
        @logger.info "STREAM %2s | keep-alive" % id
      else
        parser << chunk
      end
    end
    # finish
    http.callback do
      @logger.error "STREAM %2s | Finished by Site Streams" % id
    end
    http.errback do
      @logger.info "STREAM %2s | Finished by Fetcher" % id
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
        @logger.info "METHOD | Received | %s" % msg
        case msg
        when "start", "restart"
          unless follows.empty?
            http.close_connection if http
            http = stream_request(id+=1,follows,oauth_consumer,oauth_access_token)
          end
        when "reload"
          if http.nil?
            operation_queue.publish("start")
          elsif @reloading
            @logger.warn "METHOD | Received in reloading | %s" % msg
          else
            http_old = http
            @reloading = true
            http = stream_request(id+=1,follows,oauth_consumer,oauth_access_token)
            timer = EM.add_periodic_timer(1) {
              if @duplicate
                http_old.close_connection
                @reloading = false
                @duplicate = false
                @id_set.clear
                timer.cancel
              end
            }
          end
        when "stop"
          EM.stop
        else
          @logger.error "METHOD | Received Undefined | %s" % msg
        end
      end

      operation_queue.publish("start")
    end
  end
end

logger = Logger.new(ARGV[0]||STDOUT,'daily')
fetcher = Fetcher.new(logger)
fetcher.start
