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
    return unless pull_request_updated_countries_json?
    if opened_or_synchronized?
      create_deployment_event
    elsif merged?
      trigger_webhook
    end
  end

  private

  def opened_or_synchronized?
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

  def merged?
    pull_request['action'] == 'closed' && pull_request['pull_request']['merged']
  end

  def trigger_webhook
    # Find all applications with webhook urls
    # Queue up a background job to fire a webhook to each backend
  end

  def pull_request_updated_countries_json?
    files = github.pull_files(everypolitician_data_repo, pull_request['number'])
    files.map { |f| f[:filename] }.flatten.uniq.include?('countries.json')
  end

  def everypolitician_data_repo
    ENV['EVERYPOLITICIAN_DATA_REPO']
  end
end
