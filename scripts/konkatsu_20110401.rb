# vim:fileencoding=utf-8
require 'logger'
require 'rubygems'
require 'bundler'
Bundler.setup(:processor)

require 'yajl'
require 'mq'
require 'configatron'
require 'notifo'

require 'ohm'
Ohm.connect
require_relative '../model/user'
require_relative '../model/message'

class Konkatsu
  def initialize(logger)
    configatron.configure_from_yaml(File.expand_path('../../config/config.yml',__FILE__))
    raise "Add config/config.yml" if configatron.nil?
    @logger = logger
    @notifo = Notifo.new(configatron.notifo.username,configatron.notifo.secret)
  end

  def notify(user,text,title,link)
    @logger.info "NOTIFY | %-15s | to %-15s | %-10s | %s" % [user.twitter_screen_name,user.notifo_username,'Sending',text]
    begin
      result = @notifo.post(user.notifo_username,text,title,link)
      if result['response_message'] == 'OK'
        @logger.info "NOTIFY | %-15s | to %-15s | %-10s | %s" % [user.twitter_screen_name,user.notifo_username,'OK',text]
      else
        @logger.warn "NOTIFY | %-15s | to %-15s | %-10s | %s" % [user.twitter_screen_name,user.notifo_username,result['response_message'],text]
      end
    rescue
      @logger.error "NOTIFY | %-15s | to %-15s | %-10s | %s" % [user.twitter_screen_name,user.notifo_username,$!,text]
    end
  end

  def reply(screen_name)
    [
      "べっ、別に、嬉しくなんかないんだから…////",
      "Push.lyも、Boxcarも、あるんだよ",
      "こんなとき、どんな顔をすればいいか分からないの",
      "僕と婚約して、魔法夫になってよ！",
      "ありがとウサギ！",
      "君たちはいつもそうだね。unfavorite をありのままに伝えると決まって同じ反応をする。わけがわからないよ",
      "ちなみに年収はおいくらでしょうか。個人的には、あなたに特に経済力があるとは思いません。",
      "#{screen_name} くんとは、これからもいいお友達でいたいな… ",
      "え？今(プロポーズ)されてた？完全に無意識だったわー",
      "QPK (急に プロポーズが 来たので)",
      "「だが断る」",
      "【速報】【！！緊急！！】【拡散希望】【RTお願いします】【興味がなくてもリツイートを！】【できるだけ多くの人に知ってもらいたい】【本当に大変な問 題です！】【もう時間がありません。家族や友人にもこの問題を知らせてあげてください】【知らないでは済まない】【RT推奨】【絶対拡散】プロポーズされた",
      "そんなプロポーズで大丈夫か？",
      "##{screen_name}_nero",
      "「日本のプロポーズは残念」",
      "そんなことより野球しようぜ！",
      "「うわっ…私の女子力、低すぎ…」",
      "この婚約指輪、高かったんでしょ？（じつは半額以下だったなんて、言えない...）",
      "アタシ

Notwife

バージョン？

２３

まぁ今年で２４

ユーザ？

まぁ

当たり前に

いる

てか

いない訳ないじゃん

みたいな ",
      "私の女子力は53万です",
      "えるしっているか よめはあきなすしかたべない",
      "おまえは今まで受けたPushの回数をおぼえているのか？",
      "「ガシッ！ボカッ！」#{screen_name}は死んだ。プロポーズ（笑）",
      "俺、この通知が終わったら結婚するんだ",
      "恋愛体質（笑）女磨き（笑）Ｗハッピー婚（笑）自立した大人の女性（笑）プロポーズ（笑）",
      "エターナルフォースプロポーズ　相手は死ぬ",
      "「ペロ･･･これはプロポーズ！」バーローwww",
      "お前はなにを言ってるんだ？",
      "どうせ、他のプッシュ系サービスにも、同じこと言ってるんでしょ… ",
      "つまり・・・ どういうことだってばよ・・・？",
      "灼熱の炎がさ… 灼熱の炎が… ほら 灼熱の炎が…
(あなたのこと本気で好きになったかもしんない…)",
    ].sample
  end

  def filter(user,message)
    type = Message.type(message)

    case type
    when Message::TWEET
      if message['entities']['hashtags'].any? {|hashtag| hashtag['text'] == "notwife" } && message['user']['id'].to_s == user.twitter_id
        introduction = "Thank you for your tweet with #notwife.
I will reply to your message later.
Please keep on your eyes on inbox !!!"
        title = "konkatsu"
        link = "http://notwife.heroku.com/information"
        EM.defer(proc{
          notify(user,introduction,title,link)
          notify(user,reply(user.twitter_screen_name),title,link)
        })
      end
    end
  end

  def start
    parser = Yajl::Parser
    @logger.info "Start Konkatsu"
    AMQP.start do
      amq = MQ.new
      q = amq.queue('konkatsu')
      q.bind(amq.fanout('stream')).subscribe do |msg|
        begin
          data = parser.parse(msg)
          user = User.find(:twitter_id => data['for_user']).first
          if user and message = data['message']
            filter(user,message)
          else
            @logger.error "Invalid user or data: %s, %s, %s" % [user.twitter_id, user.twitter_screen_name,msg]
          end
        rescue
          @logger.error "Invalid message %s, %s" % [msg,$!]
        end
      end
      trap("TERM") {
        @logger.warn "Finish"
        q.delete
        AMQP.stop{EM.stop}
      }
      trap("INT")  {
        @logger.warn "Finish"
        q.delete
        AMQP.stop{EM.stop}
      }
    end
  end
end

logger = Logger.new(ARGV[0]||STDOUT,'daily')
konkatsu = Konkatsu.new(logger)
konkatsu.start
