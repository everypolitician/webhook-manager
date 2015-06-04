require 'github'
require 'date'

# Update viewer-sinatra repo with new countries from push event.
class UpdateViewerSinatraJob
  include Sidekiq::Worker
  include Github

  attr_reader :push
  attr_reader :viewer_sinatra_repo

  def perform(push)
    @push = push
    @viewer_sinatra_repo = ENV.fetch('VIEWER_SINATRA_REPO')

    new_pull_request if push_ref_is_master? && countries_json_pushed?
  end

  private

  def push_ref_is_master?
    push['ref'] == 'refs/heads/master'
  end

  def countries_json_pushed?
    files = push['commits'].map do |commit|
      commit['added'] + commit['modified']
    end
    files = files.flatten.uniq
    files.any? { |file| file =~ /^countries.json$/ }
  end

  def datasource
    @datasource ||= github.contents(viewer_sinatra_repo, path: 'DATASOURCE')
  end

  def new_pull_request
    branch_name = "update_countries.json-#{timestamp}"
    message = "Update #{datasource[:name]}"
    master_sha = github.ref(viewer_sinatra_repo, 'heads/master')[:object][:sha]
    github.create_ref(viewer_sinatra_repo, "heads/#{branch_name}", master_sha)
    github.update_contents(
      viewer_sinatra_repo,
      datasource[:path],
      message,
      datasource[:sha],
      countries_json_url,
      branch: branch_name
    )
    github.create_pull_request(
      viewer_sinatra_repo,
      'master',
      branch_name,
      message
    )
  end

  def countries_json_url
    'https://raw.githubusercontent.com/everypolitician/everypolitician-data/' \
      "#{push['after']}/countries.json"
  end

  def timestamp
    DateTime.now.strftime('%Y%m%d%H%M%S')
  end
end
