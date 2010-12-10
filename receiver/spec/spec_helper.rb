require 'bundler/setup'
require 'rspec'
require 'rack/test'
require 'rr'

module RR
  module Adapters
    module Rspec
      def self.included(mod)
        RSpec.configuration.backtrace_clean_patterns.push(RR::Errors::BACKTRACE_IDENTIFIER)
      end
    end
  end
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.mock_with :rr
  RSpec::Core::ExampleGroup.send(:include, RR::Adapters::Rspec)
end
