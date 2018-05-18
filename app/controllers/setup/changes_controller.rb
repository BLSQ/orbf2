class Setup::ChangesController < PrivateController
  def index
    # to have the current project in the private controller layouts/header
    current_project
    @versions = current_user.program.versions.order("id DESC").limit(100)
  end
end
