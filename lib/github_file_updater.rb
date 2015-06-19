require 'date'
require 'github'

# Update GitHub file on a given branch
class GithubFileUpdater
  attr_reader :github_repository
  attr_reader :github
  attr_accessor :path
  attr_reader :branch
  attr_reader :ref

  def initialize(github_repository, github = Github.github)
    @github_repository = github_repository
    @github = github
  end

  def update(contents)
    options = { branch: branch }
    options[:sha] = file[:sha] if file_exists?
    github.create_contents(
      github_repository,
      path,
      message,
      contents,
      options
    ) if Base64.decode64(file.content) != contents
  end

  def branch=(branch)
    @branch = branch
    begin
      @ref = github.ref(github_repository, "heads/#{branch}")
    rescue Octokit::NotFound
      @ref = github.create_ref(github_repository, "heads/#{branch}", master_sha)
    end
  end

  def message
    @message ||= "Update #{path}"
  end

  private

  def file
    @file ||= github.contents(github_repository, path: path, ref: ref.ref)
  end

  def file_exists?
    !file.nil?
  rescue Octokit::NotFound
    false
  end

  def master_sha
    @master_sha ||= github.ref(
      github_repository, 'heads/master'
    )[:object][:sha]
  end
end
