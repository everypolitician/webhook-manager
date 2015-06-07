require 'spec_helper'

describe Github do
  class TestDummy
    include Github
  end

  GithubDummyClient = Struct.new(:login, :access_token)

  subject { TestDummy.new }

  describe '#github' do
    it 'is an Octokit::Client' do
      assert subject.github.instance_of?(Octokit::Client)
    end
  end

  describe '#clone_url' do
    before do
      def subject.github
        GithubDummyClient.new('bob', 's3cret')
      end
    end

    it 'adds the github login and access_token' do
      url = subject.clone_url('https://example.org/repo.git')
      assert_equal 'https://bob:s3cret@example.org/repo.git', url.to_s
    end
  end
end
