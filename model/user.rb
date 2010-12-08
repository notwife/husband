require 'ohm'

class User < Ohm::Model
  attribute :twitter_id
  attribute :twitter_screen_name
  attribute :notifo_username

  index :twitter_id
  def validate
    assert_unique :twitter_id
    assert_present :twitter_screen_name
    assert_present :notifo_username
  end
end
