source 'http://rubygems.org'

group :receiver do
  gem 'sinatra'
  gem 'configatron'
  gem 'ohm'
  gem 'bunny'
end

group :processor do
  gem 'yajl-ruby', :require => 'yajl'
  gem 'amqp', :require => 'mq'
  gem 'configatron'
  gem 'em-http-request', :require => 'em-http'
  gem 'oauth'
  gem 'configatron'
  gem 'notifo', ">=0.1.2", :git => "git://github.com/phsr/notifo"
  gem 'ohm'
  gem 'god'
end

group :test do
  gem 'rspec'
  gem 'rack-test', :require => 'rack/test'
  gem 'rr'
  gem 'em-spec', :git => 'git://github.com/kfaustino/em-spec.git'
  gem 'webmock'
  gem 'fabrication'
  gem 'ffaker'
end
