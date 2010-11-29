# vim:fileencoding=utf-8
require 'logger'
require 'rubygems'
require 'bundler'
Bundler.setup(:processor)

require 'configatron'
require 'notifo'

require 'ohm'
Ohm.connect
require_relative '../model/user'

class Information
  def initialize(logger)
    configatron.configure_from_yaml(File.expand_path('../../config/config.yml',__FILE__))
    raise "Add config/config.yml" if configatron.nil?
    @logger = logger
    @notifo = Notifo.new(configatron.notifo.username,configatron.notifo.secret)
  end

  def send(notifo_username,text,title,link)
    result = @notifo.post(notifo_username,text,title,link)
    if result['response_message'] == 'OK'
      @logger.info "NOTIFY | to %-15s | %-10s | %s" % [notifo_username,'OK',text]
    else
      @logger.warn "NOTIFY | to %-15s | %-10s | %s" % [notifo_username,result['response_message'],text]
    end
  end
end

logger = Logger.new(ARGV[0]||STDOUT,'daily')
information = Information.new(logger)
text = "サービス停止の可能性について http://notwife.heroku.com/information"
title = "information"
link = "http://notwife.heroku.com/information"

User.all.map{|user|
  user.notifo_username
}.sort.each{|notifo_username|
  information.send(notifo_username,text,title,link)
  sleep 3
}
