require 'spec_helper'

describe 'Submissions' do
  def app
    Submissions
  end

  it 'requires basic auth to view submissions for an app' do
    get '/'
    assert last_response.unauthorized?
  end

  describe 'authorized requests' do
    before do
      user = User.create(
        name: 'Bob',
        email: 'bob@example.org',
        github_uid: 42,
        github_token: 'abc123'
      )
      @application = user.add_application(name: 'test')
    end

    it 'is successful' do
      basic_authorize @application.app_id, @application.secret
      get '/'
      assert last_response.ok?
    end
  end
end
