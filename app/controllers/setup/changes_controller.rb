class Setup::ChangesController < PrivateController

	def index
		@versions = Version.where(whodunnit: current_user).map do  |k| {
				:item_type => k[:item_type],
				:email => User.find_by_id(k[:whodunnit]).email,
				:event => k[:event],
				:object => k[:object]
			}
		end
	end
end
