require 'date'
require 'github'

# Update viewer-sinatra's DATASOURCE file.
class DatasourceUpdate
  include Github

  attr_reader :branch_name
  attr_reader :countries_json_url

  def initialize(new_sha)
    timestamp = DateTime.now.strftime('%Y%m%d%H%M%S')
    @branch_name = "update_countries.json-#{timestamp}"
    @countries_json_url = 'https://raw.githubusercontent.com/' \
      'everypolitician/everypolitician-data/' \
      "#{new_sha}/countries.json"
  end

  def update
    create_ref
    update_contents
    create_pull_request
  end

  private

  def create_ref
    github.create_ref(viewer_sinatra_repo, "heads/#{branch_name}", master_sha)
  end

  def update_contents
    github.update_contents(
      viewer_sinatra_repo,
      datasource[:path],
      message,
      datasource[:sha],
      countries_json_url,
      branch: branch_name
    )
  end

  def create_pull_request
    github.create_pull_request(
      viewer_sinatra_repo,
      'master',
      branch_name,
      message
    )
  end

  def viewer_sinatra_repo
    @viewer_sinatra_repo ||= ENV.fetch('VIEWER_SINATRA_REPO')
  end

  def master_sha
    @master_sha ||= github.ref(
      viewer_sinatra_repo, 'heads/master'
    )[:object][:sha]
  end

  def datasource
    @datasource ||= github.contents(viewer_sinatra_repo, path: 'DATASOURCE')
  end

  def message
    @message ||= "Update #{datasource[:name]}"
  end
end
