require 'spec_helper'

describe DatasourceUpdate do
  let(:github) { Minitest::Mock.new }
  subject do
    DatasourceUpdate.new(ENV['VIEWER_SINATRA_REPO'], 'DATASOURCE', github)
  end
  let(:countries_json_url) do
    'https://raw.githubusercontent.com/everypolitician/everypolitician-data/' \
      'bb09fbe/countries.json'
  end

  before :each do
    github.expect(
      :contents,
      { name: 'DATASOURCE', path: 'DATASOURCE', sha: 'abc123' },
      [ENV['VIEWER_SINATRA_REPO'], { path: 'DATASOURCE' }]
    )
    github.expect(
      :ref,
      { object: { sha: 'def456' } },
      [ENV['VIEWER_SINATRA_REPO'], 'heads/master']
    )
    github.expect(
      :create_ref,
      true,
      [ENV['VIEWER_SINATRA_REPO'], "heads/#{subject.branch_name}", 'def456']
    )
    github.expect(
      :update_contents,
      true,
      [
        ENV['VIEWER_SINATRA_REPO'],
        'DATASOURCE',
        'Update DATASOURCE',
        'abc123',
        countries_json_url,
        branch: subject.branch_name
      ]
    )
    github.expect(
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
      subject.update(countries_json_url)
      github.verify
    end
  end
end
