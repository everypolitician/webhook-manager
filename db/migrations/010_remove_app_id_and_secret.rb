Sequel.migration do
  change do
    alter_table(:applications) do
      drop_column :app_id
      drop_column :secret
    end
  end
end
