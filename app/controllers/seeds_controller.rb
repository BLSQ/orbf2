class SeedsController  < PrivateController

  def index
    current_user.project = ProjectFactory.new.build(dhis2_url: "http://play.dhis2.org/demo", user:"admin", password: "district", bypass_ssl: false)
    current_user.save!
  end
end
