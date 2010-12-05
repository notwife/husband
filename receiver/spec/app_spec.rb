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
          post '/new', keyword: user_params.merte(keyword: 'INVALID_KEYWORD')
        }.to raise_error
      end
    end

    context 'with valid keyword' do
      before :all do
        mock(User).create(user_params)
        mock.instance_of(Bunny::Queue).publish('reload')

        post '/new', user_params.merge(keyword: configatron.husband.keyword)
      end

      it { should be_ok }
    end
  end
end
