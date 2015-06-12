# Checks for everypolitician-data pull requests and creates deployment events
class HandleEverypoliticianDataPullRequestJob
  include Sidekiq::Worker

  attr_accessor :pull_request
  attr_reader :github

  def perform(pull_request, github = Github.github)
    @pull_request = pull_request
    @github = github
    create_deployment_event if valid? && pull_request_updated_countries_json?
  end

  private

  def valid?
    if %w(action synchronize).include?(pull_request['action'])
      repository = pull_request['repository']['full_name']
      repository == ENV['EVERYPOLITICIAN_DATA_REPO']
    end
    false
  end

  def create_deployment_event
    github.create_deployment(
      everypolitician_data_repo,
      pull_request_ref,
      payload: { pull_request_number: pull['number'] }
    )
  end

  def pull_request_ref
    pull_request['pull_request']['head']['ref']
  end

  def pull_request_updated_countries_json?
    commits = github.pull_commits(
      everypolitician_data_repo,
      pull_request['number']
    )
    files = commits.map do |commit|
      commit['added'] + commit['modified']
    end
    files.flatten.uniq.include?('countries.json')
  end

  def everypolitician_data_repo
    ENV['EVERYPOLITICIAN_DATA_REPO']
  end
end
