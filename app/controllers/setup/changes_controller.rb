class Setup::ChangesController < PrivateController

	def index
		@versions = Version.where(whodunnit: current_user)
	end
end