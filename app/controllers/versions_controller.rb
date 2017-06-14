class VersionsController < ApplicationController
	
	def index
		 @versions = Version.all
	end
end
