require 'spec_helper'

describe 'App' do
  it 'has a homepage' do
    get '/'
    assert last_response.ok?
  end

  describe 'login' do
    it 'creates a new user if none found' do
      assert_difference 'User.count', 1 do
        get '/auth/github'
        follow_redirect!
      end
      assert_equal 'http://example.org/auth/github/callback', last_request.url
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

  describe 'GitHub webhooks' do
    it 'rejects invalid signatures' do
      post '/new-pull-request',
           {},
           'HTTP_X_HUB_SIGNATURE' => 'sha1=invalid',
           'HTTP_X_GITHUB_EVENT' => 'pull_request'
      assert_equal 500, last_response.status
      assert_equal "Signatures didn't match!", last_response.body
    end

    it 'accepts valid signatures' do
      sha1 = OpenSSL::Digest.new('sha1')
      body = JSON.generate(
        'action' => 'opened',
        'pull_request' => {
          'user' => {
            'login' => 'seepoliticianstweetbot'
          }
        },
        'repository' => {
          'full_name' => 'test/everypolitician-data'
        }
      )
      signature = 'sha1=' + OpenSSL::HMAC.hexdigest(
        sha1,
        app.github_webhook_secret,
        body
      )
      MergeJob.stub(:perform_async, true) do
        post '/new-pull-request',
             body,
             'HTTP_X_HUB_SIGNATURE' => signature,
             'HTTP_X_GITHUB_EVENT' => 'pull_request'
      end
      assert last_response.ok?
      assert_equal 'OK', last_response.body
    end
  end
end
