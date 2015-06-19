# Creates or updates viewer-sinatra pull requests
class DeployViewerSinatraPullRequestJob
  include Sidekiq::Worker

  attr_reader :deployment
  attr_reader :github
  attr_reader :github_updater

  def initialize(github = Github.github, github_updater = GithubFileUpdater)
    @github = github
    @github_updater = github_updater
  end

  def perform(deployment)
    @deployment = deployment
    countries_json_url = 'https://raw.githubusercontent.com/' \
      'everypolitician/everypolitician-data/' \
      "#{everypolitician_data_pull_request.head.sha}/countries.json"
    updater = github_updater.new(github_repository)
    updater.path = 'DATASOURCE'
    updater.branch = branch_name
    updater.update(countries_json_url)
    create_pull_request(updater.message) if existing_pull.nil?
  end

  private

  def existing_pull
    pulls = github.pull_requests(ENV['VIEWER_SINATRA_REPO'])
    pulls.find { |pull| pull[:head][:ref] == branch_name }
  end

  def create_pull_request(message)
    github.create_pull_request(
      github_repository,
      'master',
      branch_name,
      message,
      pull_request_body
    )
  end

  def pull_request_body
    @full_description ||= [
      "Commits:\n",
      list_of_commit_messages,
      '',
      everypolitician_data_pull_request.html_url
    ].join("\n")
  end

  def everypolitician_data_pull_request
    @pull_request ||= github.pull(
      deployment['repository']['full_name'],
      pull_request_number
    )
  end

  def list_of_commit_messages
    commits = github.pull_commits(
      deployment['repository']['full_name'],
      pull_request_number
    )
    messages = commits.map do |commit|
      commit.commit.message.lines.first.chomp
    end
    messages.map { |m| "- #{m}" }.join("\n")
  end

  def github_repository
    @github_repository ||= ENV.fetch('VIEWER_SINATRA_REPO')
  end

  def pull_request_number
    deployment['deployment']['payload']['pull_request_number']
  end

  def branch_name
    "everypolitician-data-pr-#{pull_request_number}"
  end
end
