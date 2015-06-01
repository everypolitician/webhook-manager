require 'github'

# Background job that merges pull requests.
class MergeJob
  include Sidekiq::Worker
  include Github

  def perform(pull_request)
    action = pull_request['action']
    user = pull_request['pull_request']['user']['login']
    return if action != 'opened' || user != 'seepoliticianstweetbot'
    repo = pull_request['repository']['full_name']
    number = pull_request['number']
    github.merge_pull_request(repo, number)
  end
end
