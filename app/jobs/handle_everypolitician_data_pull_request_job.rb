# Checks for everypolitician-data pull requests and creates deployment events
class HandleEverypoliticianDataPullRequestJob
  include Sidekiq::Worker

  attr_accessor :pull_request
  attr_reader :github

  def initialize(github = Github.github)
    @github = github
  end

  def perform(pull_request)
    @pull_request = pull_request
    create_deployment_event if valid? && pull_request_updated_countries_json?
  end

  private

  def valid?
    %w(opened synchronize).include?(pull_request['action']) &&
      pull_request['repository']['full_name'] == everypolitician_data_repo
  end

  def create_deployment_event
    github.create_deployment(
      everypolitician_data_repo,
      pull_request['pull_request']['head']['ref'],
      environment: 'viewer-sinatra',
      payload: { pull_request_number: pull_request['number'] }
    )
  end

  def pull_request_updated_countries_json?
    files = github.pull_files(everypolitician_data_repo, pull_request['number'])
    files.map { |f| f[:filename] }.flatten.uniq.include?('countries.json')
  end

  def everypolitician_data_repo
    ENV['EVERYPOLITICIAN_DATA_REPO']
  end
end
