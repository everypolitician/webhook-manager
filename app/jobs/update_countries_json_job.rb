# Updates the countries.json file for a given everypolitician-data branch
class UpdateCountriesJsonJob
  include Sidekiq::Worker
  include Everypoliticianbot::Github

  def perform(branch)
    message = 'Refresh countries.json'
    options = { branch: branch, message: message }
    with_git_repo(everypolitician_data_repo, options) do
      # Unset bundler environment variables so it uses the correct Gemfile etc.
      env = {
        'BUNDLE_GEMFILE' => nil,
        'BUNDLE_BIN_PATH' => nil,
        'RUBYOPT' => nil,
        'RUBYLIB' => nil
      }
      system(env, 'bundle install')
      system(env, 'bundle exec rake countries.json')
    end
  end

  private

  def everypolitician_data_repo
    ENV['EVERYPOLITICIAN_DATA_REPO']
  end
end
