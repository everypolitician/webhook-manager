require 'spec_helper'

describe 'App' do
  it 'has a homepage' do
    get '/'
    assert last_response.ok?
  end

  it 'processes webhooks' do
    body = {
      action: 'opened',
      number: '42',
      pull_request: {
        head: {
          sha: 'abc123'
        }
      }
    }.to_json
    user = User.create(name: 'Foo', email: 'foo@example.com', github_uid: '12', github_token: 'abc')
    user.add_application(name: 'Test', webhook_url: 'http://example.org')
    assert_equal 0, SendWebhookJob.jobs.size
    post '/', body, 'HTTP_X_GITHUB_EVENT' => 'pull_request', 'HTTP_X_HUB_SIGNATURE' => body_signature(body)
    assert_equal 200, last_response.status
    assert_equal 1, SendWebhookJob.jobs.size
    assert_equal ['http://example.org', 'pull_request_opened', '42', 'abc123'], SendWebhookJob.jobs.first['args']
    assert_equal "Dispatched 1 webhooks", last_response.body
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

  describe SendWebhookJob do
    it 'dispatches webhook' do
      stub_request(:post, 'http://example.com/').to_return(status: 200)
      send_webhook_job = SendWebhookJob.new
      send_webhook_job.perform('http://example.com', 'pull_request_opened', '42', 'abc123')
      body = '{"countries_json_url":"https://cdn.rawgit.com/everypolitician/everypolitician-data/abc123/countries.json","pull_request_url":"https://api.github.com/repos/everypolitician/everypolitician-data/pulls/42"}'
      assert_requested :post, 'http://example.com', body: body, times: 1
    end
  end
end
