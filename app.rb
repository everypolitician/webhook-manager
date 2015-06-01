require 'bundler'
Bundler.require
Dotenv.load

require 'openssl'
require 'json'

# Mixin to provide a GitHub client.
module Github
  def github
    @github ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def clone_url(uri)
    repo_clone_url = URI.parse(uri)
    repo_clone_url.user = github.login
    repo_clone_url.password = github.access_token
    repo_clone_url
  end

  def with_tmp_dir(&block)
    Dir.mktmpdir do |tmp_dir|
      Dir.chdir(tmp_dir, &block)
    end
  end

  def git_clone(repo_name)
    repo = github.repository(repo_name)
    with_tmp_dir do
      `git clone -q #{clone_url(repo.clone_url)} .`
      yield
    end
  end
end

# Background job that merges pull requests.
class MergeJob
  include Sidekiq::Worker
  include Github

  def perform(repo, number)
    github.merge_pull_request(repo, number)
  end
end

class UpdateViewerSinatraJob
  include Sidekiq::Worker
  include Github

  def perform(push)
    added_files = push['commits'].map do |commit|
      commit['added']
    end
    added_files = added_files.flatten.uniq
    final_json = added_files.select { |file| file =~ /final.json$/ }
    files_to_update = {}
    git_clone(push['repository']['full_name']) do |dir|
      final_json.each do |file|
        match = file.match(/^data\/(?<country>\w+)/)
        country = match[:country]
        sha_updated = `git log --format='%h|%at' -1 #{file}`
        files_to_update[country] = sha_updated
      end
    end

    git_clone('chrismytton/viewer-sinatra') do
      git_config = "-c user.name='#{github.login}' -c user.email='#{github.emails.first[:email]}'"
      files_to_update.each do |country, sha_updated|
        path = "src/#{country}.src"
        File.open(path, 'w') { |file| file.puts(sha_updated) }
        `git add .`
        message = "#{country}: Initial data"
        `git #{git_config} commit --message="#{message}"`
      end
      `git push --quiet origin master`
    end
  end
end

configure do
  set :github_webhook_secret, ENV['GITHUB_WEBHOOK_SECRET']
end

helpers do
  HMAC_DIGEST = OpenSSL::Digest.new('sha1')

  def payload_body
    request.body.rewind
    payload_body = request.body.read
    verify_signature(payload_body)
    payload_body
  end

  # Taken from https://developer.github.com/webhooks/securing/
  def verify_signature(payload_body)
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(
      HMAC_DIGEST,
      settings.github_webhook_secret,
      payload_body
    )
    signatures_match = Rack::Utils.secure_compare(
      signature,
      request.env['HTTP_X_HUB_SIGNATURE']
    )
    return halt 500, "Signatures didn't match!" unless signatures_match
  end
end

post '/github_events' do
  pull_request = JSON.parse(payload_body)
  type = request.env['HTTP_X_GITHUB_EVENT']
  action = pull_request['action']
  user = pull_request['pull_request']['user']['login']
  if type == 'pull_request' && action == 'opened' &&
     user == 'seepoliticianstweetbot'
    repo = pull_request['repository']['full_name']
    number = pull_request['number']
    MergeJob.perform_async(repo, number)
  end
  'OK'
end

# Check for new countries
post '/everypolitician-data-push' do
  type = request.env['HTTP_X_GITHUB_EVENT']
  if type == 'push'
    push = JSON.parse(payload_body)
    UpdateViewerSinatraJob.perform_async(push)
  end
  'OK'
end
