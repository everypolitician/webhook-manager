require 'github'

# Create a pull request on GitHub
class GithubPullRequest
  attr_reader :github_repository
  attr_reader :github

  def initialize(github_repository, github = Github.github)
    @github_repository = github_repository
    @github = github
  end

  def create(branch_name, message, body = nil)
    github.create_pull_request(
      github_repository,
      'master',
      branch_name,
      message,
      body
    )
  end
end
