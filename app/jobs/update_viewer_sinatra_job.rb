require 'github_file_updater'

# Update viewer-sinatra repo with new countries from push event.
class UpdateViewerSinatraJob
  include Sidekiq::Worker

  attr_accessor :push

  def perform(push)
    @push = push
    countries_json_url = 'https://raw.githubusercontent.com/' \
      'everypolitician/everypolitician-data/' \
      "#{push['after']}/countries.json"
    return unless push_valid?
    github_repository = ENV.fetch('VIEWER_SINATRA_REPO')
    updater = GithubFileUpdater.new(github_repository, 'DATASOURCE')
    updater.update(countries_json_url)
  end

  def push_valid?
    push_ref_is_master? && countries_json_pushed?
  end

  def push_ref_is_master?
    push['ref'] == 'refs/heads/master'
  end

  def countries_json_pushed?
    files = push['commits'].map do |commit|
      commit['added'] + commit['modified']
    end
    files.flatten.uniq.include?('countries.json')
  end
end
