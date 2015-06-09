require 'date'
require 'github'

# Update GitHub file and open pull request
class GithubFileUpdater
  attr_reader :github_repository
  attr_reader :file_path
  attr_reader :github
  attr_reader :branch_name

  def initialize(github_repository, file_path, github = Github.github)
    @github_repository = github_repository
    @file_path = file_path
    @github = github
    timestamp = DateTime.now.strftime('%Y%m%d%H%M%S')
    @branch_name = "data-update-#{timestamp}"
  end

  def update(contents)
    create_ref
    update_contents(contents)
    create_pull_request
  end

  private

  def file
    @file ||= github.contents(github_repository, path: file_path)
  end

  def create_ref
    github.create_ref(github_repository, "heads/#{branch_name}", master_sha)
  end

  def update_contents(contents)
    github.update_contents(
      github_repository,
      file[:path],
      message,
      file[:sha],
      contents,
      branch: branch_name
    )
  end

  def create_pull_request
    github.create_pull_request(
      github_repository,
      'master',
      branch_name,
      message
    )
  end

  def master_sha
    @master_sha ||= github.ref(
      github_repository, 'heads/master'
    )[:object][:sha]
  end

  def message
    @message ||= "Update #{file[:name]}"
  end
end
