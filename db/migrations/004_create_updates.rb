Sequel.migration do
  change do
    create_table(:updates) do
      primary_key :id
      String :field, null: false
      String :value, null: false
      foreign_key :submission_id, :submissions, null: false, index: true
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
