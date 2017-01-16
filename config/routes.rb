
Rails.application.routes.draw do
  if ENV["ADMIN_PASSWORD"]
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      username == "admin" && password == ENV["ADMIN_PASSWORD"]
    end
  end

  mount RailsAdmin::Engine => "/admin", as: "rails_admin"

  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "home#index"
  devise_scope :user do
    get "/users/sign_out" => "devise/sessions#destroy"
    namespace :setup do
      get "/projects/", to: "setup#index", as: "project_anchor"
      get "/projects/:project_id", to: "setup#index", as: "project"
      resources :seeds, only: [:index] if Rails.env.development? || Rails.env.dev?
      resources :projects, only: [:create] do
        resource :main_entity_group, only: [:create, :update]
        resources :packages, only: [:new, :create] do
          resources :rules, only: [:new, :create, :update, :edit]
        end
        resources :incentives, only: [:new, :create, :update]
        resources :rules, only: [:new, :create, :update, :edit], controller: "project_rules"
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
