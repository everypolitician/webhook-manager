Sequel.migration do
  change do
    create_table(:applications) do
      primary_key :id
      String :name, null: false
      String :secret, null: false
      String :webhook_url
      foreign_key :user_id, :users, null: false, index: true
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
