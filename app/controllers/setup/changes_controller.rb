class Setup::ChangesController < PrivateController
  def index
    @versions = current_user.program.versions.order("id DESC").limit(100)
  end
end
