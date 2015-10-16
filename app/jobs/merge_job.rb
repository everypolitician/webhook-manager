# Background job that merges pull requests.
class MergeJob
  include Sidekiq::Worker

  def perform(pull_request)
    action = pull_request['action']
    user = pull_request['pull_request']['user']['login']
    return if action != 'opened' || !auto_merge_users.include?(user)
    repo = pull_request['repository']['full_name']
    number = pull_request['number']
    Everypoliticianbot.github.merge_pull_request(repo, number)
  end

  def auto_merge_users
    %w(everypoliticianbot seepoliticianstweetbot)
  end
end
