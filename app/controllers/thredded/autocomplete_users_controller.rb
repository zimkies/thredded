# frozen_string_literal: true
module Thredded
  class AutocompleteUsersController < Thredded::ApplicationController
    MIN_QUERY_LENGTH = 2
    MAX_RESULTS      = 20

    # pass in messageboard_id to return a list of all
    # users that can be tagged in a messageboard post.
    def index
      if params[:messageboard_id].present?
        users = Thredded.user_class.thredded_messageboards_readers([Messageboard.friendly.find(params[:messageboard_id])]).all
      else
        authorize_creating PrivateTopicForm.new(user: thredded_current_user).private_topic
        users = params.key?(:q) ? users_by_prefix : users_by_ids
      end
      render json: {
        results: users.map do |user|
          { id:         user.id,
            name:       user.send(Thredded.user_name_column),
            avatar_url: Thredded.avatar_url.call(user) }
        end
      }
    end

    private

    def users_by_prefix
      query = params[:q].to_s.strip
      if query.length >= MIN_QUERY_LENGTH
        DbTextSearch::CaseInsensitive.new(users_scope, Thredded.user_name_column).prefix(query)
          .where.not(id: thredded_current_user.id)
          .limit(MAX_RESULTS)
      else
        []
      end
    end

    # This method is used by select2 do fetch users by ids, e.g. in case of a browser-prefilled field.
    def users_by_ids
      ids = params[:ids].to_s.split(',')
      if ids.present?
        users_scope.where(id: ids)
      else
        []
      end
    end

    def users_scope
      thredded_current_user.thredded_can_message_users
    end
  end
end
