require "sidekiq/web"
require "sidekiq/throttled/web"

Rails.application.routes.draw do
  constraints CanAccessDeveloperToolsConstraint do
    mount Sidekiq::Web => "/sidekiq"
    mount Flipper::UI.app(Flipper) => '/flipper'
    Sidekiq::Throttled::Web.enhance_queues_tab!

    resources :users, only: [:index] do
      post :impersonate, on: :member
      post :stop_impersonating, on: :collection
    end
  end

  mount RailsAdmin::Engine => "/admin", as: "rails_admin"

  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "home#index"

  namespace :api do
    scope module: :v1, constraints: ApiConstraints.new(default: true) do
      resources :invoices, only: [:create]
      resources :invoicing_jobs, only: [:index, :create]
      resources :simulations, only: [:show]
      resources :workers, only:[:index]
      resources :orgunit_history, only: [:index] do
        collection do
          post :apply
        end
      end
      match "*path",
            controller:  "application",
            action:      "options",
            constraints: { method: "OPTIONS" },
            via:         [:options]
    end
    scope module: :v2, constraints: ApiConstraints.new(version: 2) do
      resource :project, only: [:show]
      resources :org_units, only: [:index]
      resources :sets, only: [:index, :show]
      resources :set_groups, only: [:index, :show]
      resources :simulations, only: [:index, :show]
      get :simulation, to: "simulations#query_based_show"

      match "*path",
            controller:  "api/v2/base_controller",
            action:      "options",
            constraints: { method: "OPTIONS" },
            via:         [:options]
    end
  end

  devise_scope :user do
    get "/users/sign_out" => "devise/sessions#destroy"
    namespace :setup do
      get "/projects/", to: "setup#index", as: "project_anchor"
      get "/projects/:project_id", to: "setup#index", as: "project"
      if Scorpio.is_dev?
        resources :seeds, only: [:index]
      end
      resources :projects, only: %i[create update] do
        resources :metadatas, only: %i[index update]
        resources :snapshots, only: [:create]
        resources :states, only: %i[new create edit update]
        resources :invoices, only: %i[new create]
        resources :formula_mappings, only: %i[new create] do
          collection do
            post :create_data_element
          end
        end
        resources :changes, only: [:index]
        resources :activities, only: %i[new create edit update mass_creation] do
          collection do
            get :mass_creation
            post :confirm_mass_creation
          end
        end
        resources :jobs, only: [:index]
        resources :publish_drafts, only: [:create]
        resource :main_entity_group, only: %i[create update]
        resources :diagnose, only: [:index, :show]
        resources :packages, only: %i[new create update edit] do
          resources :rules, only: %i[new create update edit]
        end
        resources :rules, only: %i[new create update edit index], controller: "project_rules" do
        end
        resources :datasets

        resources :autocomplete, only: [] do
          collection do
            get :organisation_units
            get :organisation_unit_group
            get :organisation_unit_group_sets
            get :data_elements
            get :indicators
            get :category_combos
          end
        end
      end
    end
  end
end
