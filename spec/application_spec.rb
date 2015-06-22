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
end
