# Represents a registered 3rd party application
class Application < Sequel::Model
  many_to_one :user
  one_to_many :submissions
  def validate
    super
    validates_presence [:name]
  end

  def before_create
    self.secret ||= SecureRandom.hex(20)
    super
  end
end
