# vim:fileencoding=utf-8
require 'rubygems'
require 'bundler'
Bundler.setup(:processer)

require 'mq'

AMQP.start do
  amq = MQ.new
  notwife_queue = MQ.new.queue('notwife')
  amq.queue('to_notwife').bind(amq.fanout('stream')).subscribe do |msg|
    puts "send msg from stream to notwife #{Time.now}"
    notwife_queue.publish(msg)
  end
end
