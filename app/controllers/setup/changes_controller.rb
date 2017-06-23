class Setup::ChangesController < PrivateController
  def index
    @versions = Version.where(program_id: current_user.program_id).order("id DESC").limit(100)
  end
end
