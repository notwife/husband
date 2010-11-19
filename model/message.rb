class Message
  [:tweet,:retweet,
    :list_member_added,:list_member_removed,
    :follow,:favorite,:unfavorite,
    :list_created,:list_updated,:list_destroyed,
    :block,:unblock,
    :friends,:delete,:direct_message
  ].each do |type|
    self.const_set(type.upcase,type)
  end

  def self.type(message)
    if message['text']
      if message['retweeted_status']
        return self::RETWEET
      else
        return self::TWEET
      end
    elsif message['event']
      case message['event']
      when 'list_member_added'
        return self::LIST_MEMBER_ADDED
      when 'list_member_removed'
        return self::LIST_MEMBER_REMOVED
      when 'follow'
        return self::FOLLOW
      when 'favorite'
        return self::FAVORITE
      when 'unfavorite'
        return self::UNFAVORITE
      when 'list_created'
        return self::LIST_CREATED
      when 'list_updated'
        return self::LIST_UPDATED
      when 'list_destroyed'
        return self::LIST_DESTROYED
      when 'block'
        return self::BLOCK
      when 'unblock'
        return self::UNBLOCK
      end
    elsif message['friends']
      return self::FRIENDS
    elsif message['delete']
      return self::DELETE
    elsif message['direct_message']
      return self::DIRECT_MESSAGE
    else
      return :unknown
    end
  end
end
