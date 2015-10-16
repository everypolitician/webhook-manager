require 'open-uri'
require 'github_file_updater'
require 'csv'
require 'date'

# Takes an approved 3rd party submission and adds it to everypolitician-data
class AcceptSubmissionJob
  include Sidekiq::Worker

  attr_reader :submission
  attr_reader :sources_directory

  def perform(submission_id)
    @submission = Submission[submission_id]
    legislature = get_legislature(submission.country, submission.legislature)
    @sources_directory = legislature['sources_directory']
    accept_submission
  end

  private

  def get_legislature(name, legislature)
    url = 'https://github.com/everypolitician/everypolitician-data/' \
      'raw/master/countries.json'
    countries = JSON.parse(open(url).read)
    country = countries.find { |c| c['slug'] == name }
    country['legislatures'].find { |l| l['slug'] == legislature }
  end

  def accept_submission
    csv = csv_from_github
    csv << CSV::Row.new(*csv_data_for(submission.updates))
    update_csv(csv.to_s)
  end

  def update_csv(csv)
    updater = GithubFileUpdater.new(github_repository)
    updater.path = csv_path
    updater.branch = "submission-#{Time.now.to_i}"
    updater.update(csv)
  end

  def csv_from_github
    csv_text = Everypoliticianbot.github.contents(
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
      sources_directory,
      submission.application.name,
      'updates.csv'
    )
  end

  def csv_data_for(updates)
    timestamp = Time.now.to_i
    headers = [:id, :field, :old, :new, :timestamp]
    rows = [headers]
    updates.each do |update|
      rows << [submission.person_id, update.field, nil, update.value, timestamp]
    end
    rows
  end
end
