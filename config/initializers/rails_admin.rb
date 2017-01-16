Kaminari.configure do |config|
  config.page_method_name = :per_page_kaminari
end

RailsAdmin.config do |config|
  EDITABLE_MODELS = %w(
    Program
    User
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
end
