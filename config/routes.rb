require "sidekiq/web"

Rails.application.routes.draw do
  if ENV["ADMIN_PASSWORD"]
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      username == "admin" && password == ENV["ADMIN_PASSWORD"]
    end
  end
  mount Sidekiq::Web => "/sidekiq"

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
      resources :projects, only: [:create, :update] do
        resources :invoices, only: [:new, :create]
        resources :activities, only: [:new, :create, :edit, :update, :mass_creation] do
          collection do
            get :mass_creation
            post :confirm_mass_creation
          end
        end
        resources :publish_drafts, only: [:create]
        resource :main_entity_group, only: [:create, :update]
        resources :packages, only: [:new, :create, :update, :edit] do
          resources :rules, only: [:new, :create, :update, :edit]
        end
        resources :incentives, only: [:new, :create, :update]
        resources :rules, only: [:new, :create, :update, :edit], controller: "project_rules"
        resources :autocomplete, only: [] do
          collection do
            get :organisation_unit_group
            get :data_elements
            get :indicators
          end
        end
      end
    end
  end
end
