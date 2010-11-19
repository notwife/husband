# vim:fileencoding=utf-8
require 'sinatra'
require 'ohm'
Ohm.connect
require_relative '../model/user'
require 'bunny'

bunny = Bunny.new
bunny.start
operation_queue = bunny.queue('operation')

get '/' do
  'hi'
end

post '/new' do
  puts User.create({:twitter_id => params['twitter_id'], :notifo_username => params['notifo_username'], :twitter_screen_name => params['twitter_screen_name']})
  operation_queue.publish("reload")
end
