class User < Ohm::Model
  attribute :twitter_id
  attribute :twitter_name
  attribute :notifo_name

  index :twitter_id
  def validate
    assert_unique :twitter_id
    assert_present :twitter_name
    assert_present :notifo_name
  end
end
