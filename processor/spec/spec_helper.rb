require 'bundler/setup'
require 'em-spec/rspec'
require 'em-http'
require 'webmock/rspec'
require 'fabrication'

module TwitterStreamSpecHelper
  class Builder
    def initialize(&block)
      @users = []
      @messages = []
      block.call(self)
    end

    def user(*users)
      @users.concat(users)
    end

    def message(*messages)
      @messages.concat(messages)
    end

    def follow
      @users.map(&:twitter_id).join(',')
    end

    def body
      encoder = Yajl::Encoder.new

      @messages.map {|m|
        json = encoder.encode(m)
        [json.size.to_s(16), json]
      }.flatten(1).join("\r\n")
    end
  end

  def stub_twitter_stream(&block)
    builder = Builder.new(&block)

    stub_request(:get, 'https://betastream.twitter.com/2b/site.json').with(
      :query => {
        :follow => builder.follow,
        :with   => 'followings'
      }
    ).to_return(
      :body    => builder.body,
      :headers => {'Transfer-Encoding' => 'chunked'}
    )
  end
end

RSpec.configure do |config|
  config.include EM::SpecHelper
  config.include TwitterStreamSpecHelper

  config.mock_with :rr
end
