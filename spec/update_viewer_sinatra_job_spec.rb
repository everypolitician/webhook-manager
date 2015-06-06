require 'spec_helper'

describe UpdateViewerSinatraJob do
  class UpdateViewerSinatraJob
    def github
      @github ||= Minitest::Mock.new
    end
  end
  subject { UpdateViewerSinatraJob.new }

  it "doesn't run when push isn't to master" do
    subject.perform({})
    subject.github.verify
  end

  it 'creates a pull request when push is to master' do
    subject.github.expect(
      :contents,
      { name: 'DATASOURCE', path: 'DATASOURCE', sha: 'abc123' },
      [ENV['VIEWER_SINATRA_REPO'], { path: 'DATASOURCE' }]
    )
    subject.github.expect(
      :ref,
      { object: { sha: 'abc123' } },
      [ENV['VIEWER_SINATRA_REPO'], 'heads/master']
    )
    subject.github.expect(
      :create_ref,
      true,
      [ENV['VIEWER_SINATRA_REPO'], String, 'abc123']
    )
    subject.github.expect(
      :update_contents,
      true,
      [
        ENV['VIEWER_SINATRA_REPO'],
        'DATASOURCE',
        'Update DATASOURCE',
        'abc123',
        String,
        Hash
      ]
    )
    subject.github.expect(
      :create_pull_request,
      true,
      [ENV['VIEWER_SINATRA_REPO'], 'master', String, String]
    )

    subject.perform(
      'ref' => 'refs/heads/master',
      'commits' => [
        {
          'added' => ['countries.json'],
          'modified' => []
        }
      ]
    )
    subject.github.verify
  end
end
