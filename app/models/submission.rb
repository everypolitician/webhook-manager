# Represents a submission from an external source
class Submission < Sequel::Model
  many_to_one :application
  one_to_many :updates

  def validate
    super
    validates_presence [:country, :person_id, :application_id]
  end
end
