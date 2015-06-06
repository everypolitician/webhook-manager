require 'sidekiq/testing'

Sidekiq::Testing.fake!

class Minitest::Spec
  before :each do
    Sidekiq::Worker.clear_all
  end
end
