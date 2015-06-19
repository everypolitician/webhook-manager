require 'spec_helper'

describe GithubFileUpdater do
  let(:github) { Minitest::Mock.new }
  subject do
    GithubFileUpdater.new(ENV['VIEWER_SINATRA_REPO'], github)
  end
  let(:countries_json_url) do
    'https://raw.githubusercontent.com/everypolitician/everypolitician-data/' \
      'bb09fbe/countries.json'
  end

  before :each do
    contents_result = { name: 'DATASOURCE', path: 'DATASOURCE', sha: 'abc123' }
    def contents_result.content
      'foo'
    end
    github.expect(
      :contents,
      contents_result,
      [ENV['VIEWER_SINATRA_REPO'], { path: 'DATASOURCE', ref: 'def' }]
    )
    ref_return = { object: { sha: 'def456' } }
    def ref_return.ref
      'def'
    end
    github.expect(
      :ref,
      ref_return,
      [ENV['VIEWER_SINATRA_REPO'], String]
    )
    github.expect(
      :create_contents,
      true,
      [
        ENV['VIEWER_SINATRA_REPO'],
        'DATASOURCE',
        'Update DATASOURCE',
        countries_json_url,
        branch: 'new-bits',
        sha: 'abc123'
      ]
    )
  end

  describe '#update' do
    it 'creates a pull request' do
      subject.path = 'DATASOURCE'
      subject.branch = 'new-bits'
      subject.update(countries_json_url)
      github.verify
    end
  end
end
