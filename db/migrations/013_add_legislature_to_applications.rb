Sequel.migration do
  change do
    alter_table(:applications) do
      add_column :legislature, String
    end
  end
end
