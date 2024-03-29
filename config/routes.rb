# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require "sidekiq/web"
require "sidekiq/throttled/web"

Rails.application.routes.draw do
  constraints CanAccessDeveloperToolsConstraint do
    mount Sidekiq::Web => "/sidekiq"
    mount Flipper::UI.app(Flipper) => "/flipper"
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

  resource :status

  namespace :api do
    scope module: :v1, constraints: ApiConstraints.new(default: true) do
      resources :invoices, only: [:create]
      resources :invoicing_jobs, only: %i[index create]
      resources :simulations, only: [:show]
      resources :workers, only: [:index]
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
      resources :de_cocs, only: [:index]
      resources :formula_mappings
      resource :calculations, only: %i[show create]
      resources :sets, only: %i[index show create update] do
        resources :inputs, only: [:create]
        resources :topic_formulas
        resources :topic_decision_tables, only: %i[index create update destroy]
        resources :set_formulas
        resources :zone_formulas
        resources :children_formulas
        resources :zone_topic_formulas
      end
      resources :compounds, only: %i[index show new create update] do
        resources :compound_formulas
      end
      resources :simulations, only: %i[index show]
      resources :topics, only: %i[index create update] do
        resources :input_mappings, only: %i[index create update destroy]
      end
      resources :users, only: %i[index create update]
      resources :changes, only: [:index]

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
    namespace :oauth do
      get "/:program_id/login", to: "oauth#dhis2_login"
      get "/:program_id/callback", to: "oauth#callback"
    end
    namespace :setup do
      get "/projects/", to: "setup#index", as: "project_anchor"
      get "/projects/:project_id", to: "setup#index", as: "project"
      resources :seeds, only: [:index] if Scorpio.is_dev?
      resources :projects, only: %i[create update] do
        resources :oauth, only: [:create]
        resources :metadatas, only: %i[index update]
        resources :snapshots, only: [:create]
        resources :states, only: %i[new create edit update destroy]
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
        resources :diagnose, only: %i[index show]
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
            get :data_elements_with_cocs
            get :indicators
            get :category_combos
            get :programs
            get :sql_views
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
