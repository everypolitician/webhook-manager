class User < Sequel::Model
  one_to_many :applications
end
