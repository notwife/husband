# vim:fileencoding=utf-8
require 'logger'
require 'rubygems'
require 'bundler'
Bundler.setup(:processor)

require 'mq'

logger = Logger.new(ARGV[0]||STDOUT,1,100000)
logger.info "Start"

AMQP.start do
  amq = MQ.new
  notwife_queue = MQ.new.queue('notwife')
  amq.queue('to_notwife').bind(amq.fanout('stream')).subscribe do |msg|
    logger.info "send msg from stream to notwife"
    notwife_queue.publish(msg)
  end
  trap("TERM") {
    logger.warn "Finish"
    stop
  }
  trap("INT")  {
    logger.warn "Finish"
    stop
  }
end
