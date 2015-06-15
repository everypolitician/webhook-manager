require 'github'
require 'open-uri'
require 'github_file_updater'
require 'csv'
require 'date'

# Takes an approved 3rd party submission and adds it to everypolitician-data
class AcceptSubmissionJob
  include Sidekiq::Worker
  include Github

  attr_reader :submission
  attr_reader :country

  def perform(submission_id)
    @submission = Submission[submission_id]
    @country = get_country(submission.country)
    accept_submission
  end

  private

  def get_country(name)
    url = 'https://github.com/everypolitician/everypolitician-data/' \
      'raw/master/countries.json'
    countries = JSON.parse(open(url).read)
    countries.find { |c| c['country'] == name }
  end

  def accept_submission
    csv = csv_from_github
    data = JSON.parse(submission.data)
    csv << CSV::Row.new(*csv_data_for(data))
    updater = GithubFileUpdater.new(github_repository, csv_path)
    updater.update(csv.to_s)
  end

  def csv_from_github
    csv_text = github.contents(
      github_repository,
      path: csv_path,
      accept: 'application/vnd.github.v3.raw'
    )
    CSV.parse(csv_text, headers: true)
  rescue Octokit::NotFound
    # No existing CSV
    CSV::Table.new([])
  end

  def github_repository
    @github_repository ||= ENV.fetch('EVERYPOLITICIAN_DATA_REPO')
  end

  def csv_path
    @csv_path ||= File.join(
      country['sources_directory'],
      "#{submission.application.name}.csv"
    )
  end

  def csv_data_for(data)
    timestamp = Time.now.to_i
    headers = [:id, :field, :old, :new, :timestamp]
    rows = [headers]
    data.each do |key, value|
      rows << [submission.person_id, key, nil, value, timestamp]
    end
    rows
  end
end
