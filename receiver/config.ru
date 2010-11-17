require 'rubygems'
require 'bundler'
Bundler.setup(:receiver,:redis,:amqp)

require './app'
run Sinatra::Application
