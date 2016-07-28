require 'spec_helper'

describe User do
  describe '#to_s' do
    it 'returns the name if the user has one' do
      assert_equal 'Bob', User.new(name: 'Bob').to_s
    end

    it 'returns the email if user has no name' do
      assert_equal 'bob@example.org', User.new(email: 'bob@example.org').to_s
    end
  end
end
