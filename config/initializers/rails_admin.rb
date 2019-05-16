Kaminari.configure do |config|
  config.page_method_name = :per_page_kaminari
end

RailsAdmin.config do |config|
  EDITABLE_MODELS = %w[
    Program
    User
    ProjectAnchor
    Project
  ].freeze

  DELETABLE_MODELS = %w[
    Program
    User
  ].freeze

  config.actions do
    dashboard do
    end
    index
    show_in_app
    export
    show
    new do
      only DELETABLE_MODELS
    end
    delete do
      only DELETABLE_MODELS
    end
    bulk_delete do
      only DELETABLE_MODELS
    end
    edit do
      only EDITABLE_MODELS
    end
  end
  config.model "User" do
    object_label_method do
      :label
    end
  end

  config.model "Dhis2Log" do
    list do
      field :id
      field :status
      field :created_at
      field :project_anchor
    end
  end

  config.model "Dhis2Snapshot" do
    list do
      field :id
      field :kind
      field :snapshoted_at
      field :created_at
      field :project_anchor
    end
  end
  config.model "ProjectAnchor" do
    show do
      field :program
      field :token
      field :projects
    end

    edit do
      field :token
    end
  end

  config.model "Project" do
    list do
      field :name
      field :dhis2_url
      field :bypass_ssl
      field :engine_version
    end
    edit do
      field :engine_version
    end
  end

  config.model "Program" do
    object_label_method do
      :label
    end
    show do
      field :code
      field :project_anchor
      field :users
    end
  end

  config.model "InvoicingJob" do
    visible { false }
  end

  config.model "Version" do
    visible { false }
  end

  if ENV["ADMIN_PASSWORD"]
    config.authorize_with do
      authenticate_or_request_with_http_basic("Authentication") do |username, password|
        username == "admin" && password == ENV["ADMIN_PASSWORD"]
      end
    end
  end
end
