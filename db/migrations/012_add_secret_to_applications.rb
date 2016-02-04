Sequel.migration do
  change do
    alter_table(:applications) do
      add_column :secret, String
    end
  end
end
