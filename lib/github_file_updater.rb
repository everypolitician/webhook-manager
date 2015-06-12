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

  def update(contents, body = nil)
    create_ref
    update_contents(contents)
    create_pull_request(body)
  end

  private

  def file
    @file ||= github.contents(github_repository, path: file_path)
  end

  def file_exists?
    !file.nil?
  rescue Octokit::NotFound
    false
  end

  def create_ref
    github.create_ref(github_repository, "heads/#{branch_name}", master_sha)
  end

  def update_contents(contents)
    options = { branch: branch_name }
    options[:sha] = file[:sha] if file_exists?
    github.create_contents(
      github_repository,
      file_path,
      message,
      contents,
      options
    )
  end

  def create_pull_request(body = nil)
    github.create_pull_request(
      github_repository,
      'master',
      branch_name,
      message,
      body
    )
  end

  def master_sha
    @master_sha ||= github.ref(
      github_repository, 'heads/master'
    )[:object][:sha]
  end

  def message
    @message ||= "Update #{file_path}"
  end
end
