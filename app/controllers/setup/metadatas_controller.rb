class Setup::MetadatasController < PrivateController
  def index
    @metadatas = Meta::MetaDataService.new(current_project)
                                      .metadatas
                                      .sort_by!(&:dhis2_id)
  end
end
