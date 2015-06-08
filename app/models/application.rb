# Represents a registered 3rd party application
class Application < Sequel::Model
  many_to_one :user
  one_to_many :submissions
  def validate
    super
    validates_presence [:name, :secret]
  end
end
