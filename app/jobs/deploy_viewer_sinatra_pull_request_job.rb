# Creates or updates viewer-sinatra pull requests
class DeployViewerSinatraPullRequestJob
  include Sidekiq::Worker

  attr_reader :deployment

  def perform(deployment)
    @deployment = deployment
    pulls = github.pull_requests(ENV['VIEWER_SINATRA_REPO'])
    existing_pull = pulls.find do |pull|
      pull[:head][:ref] == branch_name
    end
    if existing_pull
      update_pull_request(existing_pull)
    else
      create_pull_request
    end
  end

  def update_pull_request
    # Use github.update_contents to update existing pull request branch
  end

  def create_pull_request
    # Create new branch and update contents then open pull request
  end

  def branch_name
    "everypolitician-data-pr-#{deployment['payload']['pull_request_number']}"
  end
end
