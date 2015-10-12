class UpdateCountriesJsonJob
  include Sidekiq::Worker
  include Github

  class FailedSystemCall < StandardError; end

  def perform(branch)
    message = 'Refresh countries.json'
    with_git_repo(everypolitician_data_repo, branch: branch, message: message) do
      # Unset bundler environment variables so it uses the correct Gemfile etc.
      env = {'BUNDLE_GEMFILE' => nil, 'BUNDLE_BIN_PATH' => nil, 'RUBYOPT' => nil, 'RUBYLIB' => nil}
      system(env, 'bundle install')
      system(env, 'bundle exec rake countries.json')
    end
  end

  private

  def everypolitician_data_repo
    ENV['EVERYPOLITICIAN_DATA_REPO']
  end

  def system(*args)
    if !Kernel.system(*args)
      raise FailedSystemCall, "#{args} exited with #$?"
    end
  end
end
