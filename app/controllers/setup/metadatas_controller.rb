class Setup::MetadatasController < PrivateController
  def index
    @metadatas = Meta::MetaDataService.new(current_project)
                                      .metadatas
                                      .sort_by!(&:dhis2_id)
  end

  def update
    @dhis2_update_params = {
      dhis2_id:   params[:id],
      name:       params[:name],
      short_name: params[:short_name],
      code:       params[:code]
    }
    UpdateMetadataWorker.perform_async(current_project.id, @dhis2_update_params)
    render partial: "update_data_element"
  end
end
