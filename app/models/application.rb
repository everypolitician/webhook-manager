# Represents a registered 3rd party application
class Application < Sequel::Model
  many_to_one :user
  def validate
    super
    validates_presence [:name, :secret]
  end
end
