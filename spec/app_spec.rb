require 'spec_helper'

describe 'App' do
  it 'has a homepage' do
    get '/'
    assert last_response.ok?
  end

  it 'lists webhook urls' do
    get '/urls.json'
    assert last_response.ok?
    assert_equal(
      JSON.parse(last_response.body),
      'webhook_event_handler_url' => 'http://example.org/event_handler'
    )
  end

  describe 'login' do
    it 'creates a new user if none found' do
      assert_difference 'User.count', 1 do
        get '/auth/github'
        follow_redirect!
      end
      assert_equal 'http://example.org/auth/github/callback', last_request.url
      follow_redirect!
      assert last_response.body.include?(
        'You have successfully logged in with GitHub'
      )
    end

    it 'uses existing user if one exists' do
      User.create(
        name: 'Bob',
        email: 'bob@example.org',
        github_uid: '123545',
        github_token: 'abc123'
      )
      assert_difference 'User.count', 0 do
        get '/auth/github'
        follow_redirect!
      end
      assert_equal 'http://example.org/auth/github/callback', last_request.url
    end
  end

  describe 'logout' do
    it 'redirects to the homepage' do
      get '/logout'
      follow_redirect!
      assert_equal 'http://example.org/', last_request.url
      assert last_response.body.include?('You have been logged out')
    end
  end

  describe 'GitHub webhooks' do
    it 'rejects invalid signatures' do
      assert_difference 'HandleEverypoliticianDataPullRequestJob.jobs.size', 0 do
        post '/event_handler',
             {},
             'HTTP_X_HUB_SIGNATURE' => 'sha1=invalid',
             'HTTP_X_GITHUB_EVENT' => 'pull_request'
      end
      assert_equal 500, last_response.status
      assert_equal "Signatures didn't match!", last_response.body
    end

    describe '/event_handler' do
      it 'creates a HandleEverypoliticianDataPullRequestJob on pull_request' do
        body = '{}'
        assert_difference 'HandleEverypoliticianDataPullRequestJob.jobs.size',
                          1 do
          post '/event_handler',
               body,
               'HTTP_X_HUB_SIGNATURE' => body_signature(body),
               'HTTP_X_GITHUB_EVENT' => 'pull_request'
        end
        assert last_response.ok?
        assert_equal 'HandleEverypoliticianDataPullRequestJob queued',
                     last_response.body
      end

      it 'creates a new DeployViewerSinatraPullRequestJob on deployment' do
        body = '{}'
        assert_difference 'DeployViewerSinatraPullRequestJob.jobs.size', 1 do
          post '/event_handler',
               body,
               'HTTP_X_HUB_SIGNATURE' => body_signature(body),
               'HTTP_X_GITHUB_EVENT' => 'deployment'
        end
        assert last_response.ok?
        assert_equal 'DeployViewerSinatraPullRequestJob queued',
                     last_response.body
      end

      it "doesn't do anything with an unknown event type" do
        body = '{}'
        post '/event_handler',
             body,
             'HTTP_X_HUB_SIGNATURE' => body_signature(body),
             'HTTP_X_GITHUB_EVENT' => 'flargle'
        assert last_response.ok?
        assert_equal 'Unknown event type: flargle', last_response.body
      end
    end
  end
end
