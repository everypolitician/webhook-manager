# Represents an authenticated user
class User < Sequel::Model
  one_to_many :applications

  def to_s
    name || email
  end
end
