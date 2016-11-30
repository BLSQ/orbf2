Rails.application.routes.draw do
  get 'group/create'

  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "setup#index"
  devise_scope :user do
    get "/users/sign_out" => "devise/sessions#destroy"
    resource :setup do
      resources :projects do
        resources :autocomplete, only: [] do
          collection do
            get :organisation_unit_group
          end
        end
      end
    end
  end
end
