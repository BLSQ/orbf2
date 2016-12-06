Rails.application.routes.draw do

  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "setup#index"
  devise_scope :user do
    get "/users/sign_out" => "devise/sessions#destroy"
    resource :setup do
      resources :projects, only: [:create] do
        resource :main_entity_group, only: [:create, :update]
        resource :packages
        resources :autocomplete, only: [] do
          collection do
            get :organisation_unit_group
            get :data_elements
          end
        end
      end
    end
  end
end
