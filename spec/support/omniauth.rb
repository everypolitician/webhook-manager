OmniAuth.config.test_mode = true

OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
  provider: 'github',
  uid: '123545',
  info: {
    name: 'Bob Test',
    email: 'bob@example.org'
  },
  credentials: {
    token: 'abc123'
  }
)
