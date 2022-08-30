module Api::V2
  class UsersController < BaseController
    def index
      users = current_project_anchor.program.users
      options = {}
      render json: serializer_class.new(users, options).serialized_json
    end

    def create
      password = SecureRandom.hex
      attrs = user_attributes.merge(password: password)
      user = nil
      User.transaction do
        user = current_project_anchor.program.users.create!(attrs)
      end

      options = {}
      render json: serializer_class.new(user, options).serialized_json
    end

    def update
      user = current_project_anchor.program.users.find(params[:id])
      User.transaction do
        user.update!(user_attributes)
      end

      options = {}
      render json: serializer_class.new(user, options).serialized_json
    end

    private

    def serializer_class
      ::V2::UserSerializer
    end

    def user_attributes
      att = user_params[:attributes]
      {
        email:          att[:email],
        dhis2_user_ref: att[:dhis2UserRef],
        password:       att[:password]
      }
    end

    def user_params
      params.require(:data)
            .permit(attributes: [
                      :email,
                      :dhis2UserRef,
                      :password
                    ])
    end
  end
end
