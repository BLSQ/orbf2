Kaminari.configure do |config|
  config.page_method_name = :per_page_kaminari
end

RailsAdmin.config do |config|
  EDITABLE_MODELS = %w(
    Program
    User
    ProjectAnchor
  ).freeze

  DELETABLE_MODELS = %w(
    Program
    User
  ).freeze

  config.actions do
    dashboard
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
    edit do
      field :token
    end
  end
  if ENV["ADMIN_PASSWORD"]
  config.authorize_with do
    authenticate_or_request_with_http_basic("Authentication") do |username, password|
      username == "admin" && password == ENV["ADMIN_PASSWORD"]
    end
  end
end
end
