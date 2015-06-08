Sequel.migration do
  change do
    create_table(:submissions) do
      primary_key :id
      String :data, null: false
      String :country, null: false
      Integer :person_id, null: false
      foreign_key :application_id, :applications, null: false, index: true
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
