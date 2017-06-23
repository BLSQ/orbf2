class Setup::ChangesController < PrivateController
  def index
    @versions = Version.where(whodunnit: current_user).order("id DESC").limit(100)
  end
end
