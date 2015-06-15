# Represents part of a submission
class Update < Sequel::Model
  many_to_one :submission

  def validate
    super
    validates_presence [:field, :value, :submission_id]
  end
end
