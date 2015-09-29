require 'spec_helper'

describe Application do
  let(:user) do
    User.create(
      name: 'Bob',
      email: 'bob@example.org',
      github_uid: 42,
      github_token: 'abc123'
    )
  end

  subject { user.add_application(name: 'test') }

  it 'gets a secret automatically on create' do
    assert subject.secret
  end

  describe '#submission_from_payload' do
    it 'creates a submission and associated updates' do
      submission = subject.submission_from_payload(
        country: 'Foo',
        legislature: 'Bar',
        person_id: '123',
        updates: {
          twitter: 'foobarbaz'
        }
      )
      assert_equal 'Foo', submission.country
      assert_equal 'Bar', submission.legislature
      assert_equal '123', submission.person_id
      assert_equal 1, submission.updates.count
      update = submission.updates.first
      assert_equal 'twitter', update.field
      assert_equal 'foobarbaz', update.value
    end
  end
end
