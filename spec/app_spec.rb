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
      'webhook_receivers' => {
        'pull_requests' => 'http://example.org/new-pull-request',
        'pushes' => 'http://example.org/everypolitician-data-push'
      }
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
      assert_difference 'MergeJob.jobs.size', 0 do
        post '/new-pull-request',
             {},
             'HTTP_X_HUB_SIGNATURE' => 'sha1=invalid',
             'HTTP_X_GITHUB_EVENT' => 'pull_request'
      end
      assert_equal 500, last_response.status
      assert_equal "Signatures didn't match!", last_response.body
    end

    describe '/new-pull-request' do
      it 'creates a new MergeJob on pull_request' do
        body = '{}'
        assert_difference 'MergeJob.jobs.size', 1 do
          post '/new-pull-request',
               body,
               'HTTP_X_HUB_SIGNATURE' => body_signature(body),
               'HTTP_X_GITHUB_EVENT' => 'pull_request'
        end
        assert last_response.ok?
        assert_equal 'MergeJob started for pull request.', last_response.body
      end

      it "doesn't create a MergeJob if not a pull_request" do
        body = '{}'
        assert_difference 'MergeJob.jobs.size', 0 do
          post '/new-pull-request',
               body,
               'HTTP_X_HUB_SIGNATURE' => body_signature(body),
               'HTTP_X_GITHUB_EVENT' => 'not_a_pull_request'
        end
        assert last_response.ok?
        assert_equal 'No pull request detected, doing nothing.',
                     last_response.body
      end
    end

    describe '/everypolitician-data-push' do
      it 'creates a new UpdateViewerSinatraJob on push' do
        body = '{}'
        assert_difference 'UpdateViewerSinatraJob.jobs.size', 1 do
          post '/everypolitician-data-push',
               body,
               'HTTP_X_HUB_SIGNATURE' => body_signature(body),
               'HTTP_X_GITHUB_EVENT' => 'push'
        end
        assert last_response.ok?
        assert_equal 'UpdateViewerSinatraJob started for push event',
                     last_response.body
      end

      it "doesn't create an UpdateViewerSinatraJob if not a push" do
        body = '{}'
        assert_difference 'UpdateViewerSinatraJob.jobs.size', 0 do
          post '/everypolitician-data-push',
               body,
               'HTTP_X_HUB_SIGNATURE' => body_signature(body),
               'HTTP_X_GITHUB_EVENT' => 'not_a_push'
        end
        assert last_response.ok?
        assert_equal 'No push event detected, doing nothing.',
                     last_response.body
      end
    end
  end
end
