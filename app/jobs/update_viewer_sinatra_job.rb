require 'github'
require 'date'

# Update viewer-sinatra repo with new countries from push event.
class UpdateViewerSinatraJob
  include Sidekiq::Worker
  include Github

  attr_reader :push
  attr_reader :viewer_sinatra_repo

  def perform(push)
    @push = push
    @viewer_sinatra_repo = ENV.fetch('VIEWER_SINATRA_REPO')

    git_clone(viewer_sinatra_repo) do
      files_to_update.each do |country, sha_updated|
        new_pull_request_for(country, sha_updated)
      end
    end
  end

  private

  def files_to_update
    to_update = {}
    git_clone(push['repository']['full_name']) do
      final_json.each do |file|
        match = file.match(/^data\/(?<country>\w+)/)
        country = match[:country]
        sha_updated = `git log --format='%h|%at' -1 #{file}`
        to_update[country] = sha_updated
      end
    end
    to_update
  end

  def final_json
    added_files = push['commits'].map do |commit|
      commit['added']
    end
    added_files = added_files.flatten.uniq
    added_files.select { |file| file =~ /final.json$/ }
  end

  def new_pull_request_for(country, sha_updated)
    File.open("src/#{country}.src", 'w') { |file| file.puts(sha_updated) }
    branch_name = "#{country.downcase}-#{timestamp}"
    message = "#{country}: Initial data"
    git_commit_and_push(branch: branch_name, message: message)
    github.create_pull_request(
      viewer_sinatra_repo,
      'master',
      branch_name,
      message
    )
  end

  def timestamp
    DateTime.now.strftime('%Y%m%d%H%M%S')
  end
end
