require 'fabrication'
require 'ffaker'

require_relative '../../model/user'

Fabricator :user do
  twitter_id { rand(10000) }
  twitter_screen_name { Faker::Internet.user_name }
  notifo_username { Faker::Internet.user_name }

  after_create do |user|
    raise user.errors.inspect unless user.save
  end
end
