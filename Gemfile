source 'http://rubygems.org'


group :receiver do
  gem 'sinatra'
  gem 'configatron'
end

group :redis do
  gem 'ohm'
end

group :amqp do
  gem 'yajl-ruby', :require => 'yajl'
  gem 'amqp', :require => 'mq'
  gem 'bunny'
end

group :notifo do
  gem 'configatron'
  gem 'notifo', ">=0.1.2", :git => "git://github.com/phsr/notifo"
end

group :streams do
  gem 'configatron'
  gem 'em-http-request', :require => 'em-http'
  gem 'oauth'
end
