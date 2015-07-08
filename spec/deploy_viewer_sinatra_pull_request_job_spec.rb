require 'spec_helper'
require 'ostruct'

describe DeployViewerSinatraPullRequestJob do
  subject { DeployViewerSinatraPullRequestJob.new(github, github_updater) }
  let(:github) { Minitest::Mock.new }
  let(:github_updater) { Minitest::Mock.new }
  let(:updater) { Minitest::Mock.new }

  it 'updates the DATASOURCE file in viewer-sinatra' do
    pull = OpenStruct.new(head: OpenStruct.new(sha: 'abc123', ref: 'master'))
    pull_request = OpenStruct.new(html_url: 'https://example.org/pull_request/11')
    github.expect(:pull, pull, [ENV['EVERYPOLITICIAN_DATA_REPO'], 42])
    github_updater.expect(:new, updater, [ENV['VIEWER_SINATRA_REPO']])
    updater.expect(:path=, 'DATASOURCE', ['DATASOURCE'])
    updater.expect(:branch=, 'everypolitician-data-pr-42', [
      'everypolitician-data-pr-42'
    ])
    countries_json_url = 'https://raw.githubusercontent.com/everypolitician/' \
      'everypolitician-data/abc123/countries.json'
    updater.expect(:update, true, [countries_json_url])
    updater.expect(:message, 'Update DATASOURCE')
    github.expect(:pull_requests, [], [ENV['VIEWER_SINATRA_REPO']])
    github.expect(:pull_commits, [], [ENV['EVERYPOLITICIAN_DATA_REPO'], 42])
    github.expect(:create_pull_request, pull_request, [
      ENV['VIEWER_SINATRA_REPO'],
      'master',
      'everypolitician-data-pr-42',
      'Update DATASOURCE',
      String
    ])
    github.expect(:create_deployment_status, true, [
      'https://example.org/deployment/123',
      'success',
      { target_url: 'https://example.org/pull_request/11' }
    ])
    subject.perform(
      'repository' => {
        'full_name' => ENV['EVERYPOLITICIAN_DATA_REPO']
      },
      'deployment' => {
        'payload' => {
          'pull_request_number' => 42
        },
        'url' => 'https://example.org/deployment/123'
      }
    )
  end
end
