require 'spec_helper'

describe DatasourceUpdate do
  class DatasourceUpdate
    def github
      @github ||= Minitest::Mock.new
    end
  end
  subject { DatasourceUpdate.new('deedfeed') }

  before :each do
    subject.github.expect(
      :contents,
      { name: 'DATASOURCE', path: 'DATASOURCE', sha: 'abc123' },
      [ENV['VIEWER_SINATRA_REPO'], { path: 'DATASOURCE' }]
    )
    subject.github.expect(
      :ref,
      { object: { sha: 'def456' } },
      [ENV['VIEWER_SINATRA_REPO'], 'heads/master']
    )
    subject.github.expect(
      :create_ref,
      true,
      [ENV['VIEWER_SINATRA_REPO'], "heads/#{subject.branch_name}", 'def456']
    )
    subject.github.expect(
      :update_contents,
      true,
      [
        ENV['VIEWER_SINATRA_REPO'],
        'DATASOURCE',
        'Update DATASOURCE',
        'abc123',
        subject.countries_json_url,
        branch: subject.branch_name
      ]
    )
    subject.github.expect(
      :create_pull_request,
      true,
      [
        ENV['VIEWER_SINATRA_REPO'],
        'master',
        subject.branch_name,
        'Update DATASOURCE'
      ]
    )
  end

  describe '#update' do
    it 'creates a pull request' do
      subject.update
      subject.github.verify
    end
  end

  it 'updates the DATASOURCE with the correct url' do
    countries_json_url = 'https://raw.githubusercontent.com/' \
      'everypolitician/everypolitician-data/' \
      'deedfeed/countries.json'
    assert_equal countries_json_url, subject.countries_json_url
  end
end
