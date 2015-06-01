require 'github'

# Background job that merges pull requests.
class MergeJob
  include Sidekiq::Worker
  include Github

  def perform(repo, number)
    github.merge_pull_request(repo, number)
  end
end

