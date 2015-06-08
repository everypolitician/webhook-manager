# Represents a submission from an external source
class Submission < Sequel::Model
  many_to_one :application
end
