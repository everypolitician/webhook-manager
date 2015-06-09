require 'base64'
require 'date'
require 'github'
require 'open-uri'
require 'github_file_updater'

# Takes an approved 3rd party submission and adds it to everypolitician-data
class AcceptSubmissionJob
  include Sidekiq::Worker
  include Github

  attr_reader :submission

  def perform(submission_id)
    @submission = Submission[submission_id]
    accept_submission
  end

  def get_country(name)
    url = 'https://github.com/everypolitician/everypolitician-data/' \
      'raw/master/countries.json'
    countries = JSON.parse(open(url).read)
    countries.find { |c| c['name'] == name }
  end

  def accept_submission
    # TODO: Change me
    github_repository = 'chrismytton/everypolitician-data'
    country_name = submission.country.gsub(' ', '_')
    country = get_country(country_name)
    csv_path = File.join(
      country['sources_directory'],
      "#{submission.application.name}.csv"
    )
    begin
      existing_csv = github.contents(
        github_repository,
        path: csv_path
      )
      csv_text = Base64.decode64(existing_csv[:content])
      csv = CSV.parse(csv_text, headers: true)
    rescue Octokit::NotFound
      # No existing CSV
      csv = CSV::Table.new([])
    end
    data = JSON.parse(submission.data)
    headers = [:id]
    values = [submission.person_id]
    data.each do |key, value|
      headers << key
      values << value
    end
    csv << CSV::Row.new(headers, values)

    updater = GithubFileUpdater.new(github_repository, csv_path)
    updater.update(csv)
  end
end
