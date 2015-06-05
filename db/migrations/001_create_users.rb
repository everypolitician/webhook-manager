Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :name, null: false
      String :email, null: false
      String :github_uid, null: false
      String :github_token, null: false
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
