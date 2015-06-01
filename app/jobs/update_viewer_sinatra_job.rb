require 'github'

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
