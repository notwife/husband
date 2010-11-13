require 'rubygems'
require 'bundler'
Bundler.setup(:receiver)

require './app'
run Sinatra::Application
