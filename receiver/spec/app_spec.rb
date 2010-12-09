require_relative 'spec_helper'
require_relative '../app'

describe Sinatra::Application do
  def app
    described_class
  end

  before :all do
    set :environment, :test
  end

  subject { last_response }

  describe 'POST /new' do
    let(:user_params) {
      {
        twitter_id:          'alpha',
        notifo_username:     'bravo',
        twitter_screen_name: 'charlie'
      }
    }

    context 'with invalid keyword' do
      specify do
        expect {
          post '/new', keyword: user_params.merge(keyword: 'INVALID_KEYWORD')
        }.to raise_error(RuntimeError)
      end
    end

    context 'with valid keyword' do
      let(:operation_queue) { stub!.publish.subject }

      before do
        stub(User).create
        any_instance_of(app, :operation_queue => operation_queue)

        post '/new', user_params.merge(keyword: configatron.husband.keyword)
      end

      it { should be_ok }
      specify { User.should have_received.create(user_params) }
      specify { operation_queue.should have_received.publish('reload') }
    end
  end
end
