# frozen_string_literal: true

# Serves the hesabu-manager build (public/hesabu-manager, see `rake hesabu_manager:install`)
# as an alternative UI for the logged in orbf2 user, without installing it as a dhis2 app:
#
# - `show` injects the project token and the orbf2 user in the manager page
# - `dhis2` forwards a few read-only dhis2 api calls the manager needs (autocompletes,
#   names) with the project's dhis2 credentials, these never reach the browser.
class Setup::HesabuManagerController < PrivateController
  BUILD_DIR = Rails.root.join("public", "hesabu-manager")

  # dhis2 resources the manager reads, see hesabu-manager src/lib/Api.js and api.get(...) calls
  DHIS2_RESOURCES = %w[
    categoryCombos
    categoryOptionCombos
    dataElements
    identifiableObjects
    indicators
    organisationUnitGroupSets
    organisationUnitGroups
    organisationUnitLevels
    users
  ].freeze

  SEGMENT = /\A[A-Za-z0-9_\-]+(\.json)?\z/.freeze

  def show
    index = BUILD_DIR.join("index.html")
    unless index.exist?
      return render plain: "hesabu manager is not installed (#{index}), see rake hesabu_manager:install", status: :not_found
    end

    config = manager_config(current_project_anchor)
    head_tags = %(<base href="/hesabu-manager/"><script>window.HESABU_CONFIG = #{ERB::Util.json_escape(config.to_json)};</script>)
    render html: index.read.sub("<head>", "<head>#{head_tags}").html_safe, layout: false # rubocop:disable Rails/OutputSafety
  end

  def dhis2
    segments = params[:path].to_s.split("/")
    resource = segments.first.to_s.delete_suffix(".json")
    return head :forbidden unless DHIS2_RESOURCES.include?(resource) && segments.all? { |s| s.match?(SEGMENT) }

    project = current_project_anchor.project
    response = RestClient::Request.execute(
      method:     :get,
      url:        dhis2_url(project, segments),
      user:       project.user,
      password:   project.password,
      verify_ssl: !project.bypass_ssl,
      headers:    { accept: :json },
      timeout:    60
    )
    render body: response.body, status: response.code, content_type: "application/json"
  rescue RestClient::ExceptionWithResponse => e
    render body: e.response&.body, status: e.response&.code || :bad_gateway, content_type: "application/json"
  end

  private

  def manager_config(project_anchor)
    project_anchor.update_token_if_needed
    {
      token:            project_anchor.reload.token,
      url:              request.base_url,
      dhis2ApiUrl:      "#{request.base_url}/setup/manager/dhis2/api",
      dhis2Url:         project_anchor.project.dhis2_url.chomp("/"),
      user:             {
        id:          "orbf2-#{current_user.id}",
        displayName: current_user.email,
        canEdit:     true
      }
    }
  end

  def dhis2_url(project, segments)
    url = "#{project.dhis2_url.chomp('/')}/api/#{segments.join('/')}"
    request.query_string.present? ? "#{url}?#{request.query_string}" : url
  end
end
