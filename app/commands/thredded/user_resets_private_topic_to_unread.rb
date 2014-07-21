module Thredded
  class UserResetsPrivateTopicToUnread
    def initialize(private_topic, user)
      @private_topic = private_topic
      @user = user
    end

    def run
      other_users = Thredded::PrivateUser
        .where(private_topic: private_topic)
        .where('user_id != ?', user.id)
      other_users.update_all(read: false)
    end

    private

    attr_reader :private_topic, :user
  end
end