module Api::V2
  class UsersController < BaseController
    def index
      users = User.where(program_id: current_program.id)
      options = {}
      render json: serializer_class.new(users, options).serialized_json
    end

    def create
    end

    def update
    end

    private

    def current_program
      current_user.program
    end

    def serializer_class
      ::V2::UserSerializer
    end
  end
end
