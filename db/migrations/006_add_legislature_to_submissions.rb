Sequel.migration do
  change do
    alter_table(:submissions) do
      add_column :legislature, String, null: false
    end
  end
end
