require 'github'
require 'date'

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
    git_clone(push['repository']['full_name']) do
      final_json.each do |file|
        match = file.match(/^data\/(?<country>\w+)/)
        country = match[:country]
        sha_updated = `git log --format='%h|%at' -1 #{file}`
        files_to_update[country] = sha_updated
      end
    end

    viewer_sinatra_repo = ENV.fetch('VIEWER_SINATRA_REPO')

    git_clone(viewer_sinatra_repo) do
      git_config = "-c user.name='#{github.login}' -c user.email='#{github.emails.first[:email]}'"
      files_to_update.each do |country, sha_updated|
        branch_name = "#{country.downcase}-#{DateTime.now.strftime('%Y%m%d%H%M%S')}"
        `git checkout -q -b #{branch_name}`
        path = "src/#{country}.src"
        File.open(path, 'w') { |file| file.puts(sha_updated) }
        `git add .`
        message = "#{country}: Initial data"
        `git #{git_config} commit --message="#{message}"`
        `git push --quiet origin #{branch_name}`
        pull_request = github.create_pull_request(
          viewer_sinatra_repo,
          'master',
          branch_name,
          message
        )
      end
    end
  end
end
