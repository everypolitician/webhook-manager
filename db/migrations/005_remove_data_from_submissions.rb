Sequel.migration do
  change do
    alter_table(:submissions) do
      drop_column :data
    end
  end
end
