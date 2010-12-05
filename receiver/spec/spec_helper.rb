require 'bundler/setup'
require 'rspec'
require 'rack/test'
require 'rr'

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.mock_with :rr
end
