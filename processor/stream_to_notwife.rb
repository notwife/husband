# vim:fileencoding=utf-8
require 'logger'
require 'rubygems'
require 'bundler'
Bundler.setup(:processor)

require 'mq'

logger = Logger.new(ARGV[0]||STDOUT,'daily')
logger.info "Start"

AMQP.start do
  amq = MQ.new
  notwife_queue = MQ.new.queue('notwife')
  amq.queue('to_notwife').bind(amq.fanout('stream')).subscribe do |msg|
    notwife_queue.publish(msg)
  end
  trap("TERM") {
    logger.warn "Finish"
    EM.stop
  }
  trap("INT")  {
    logger.warn "Finish"
    EM.stop
  }
end
