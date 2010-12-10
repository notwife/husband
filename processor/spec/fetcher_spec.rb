# coding: utf-8
require_relative 'spec_helper'
require_relative '../fetcher'

describe Fetcher do
  default_timeout 3

  let(:user) { Fabricate(:user) }

  before :all do
    Ohm.flush
    user
  end

  context 'UserStream から tweet が流れてきたとき' do
    let(:tweet) { {:message => {:text => 'hi'}} }

    before do
      stub_twitter_stream do |s|
        s.user user
        s.message tweet
      end
    end

    it 'tweet を stream queue に送信すること' do
      em do
        # TODO ごちゃごちゃしすぎだし、複数のメッセージを扱うのが大変そう
        MQ.new.queue('fetcher_spec').bind(MQ.fanout('stream')).subscribe do |msg|
          msg.should == Yajl::Encoder.new.encode(tweet)
          done
        end

        Fetcher.new(Logger.new('/dev/null')).start
      end
    end
  end
end
