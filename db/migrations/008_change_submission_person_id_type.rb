Sequel.migration do
  change do
    alter_table(:submissions) do
      set_column_type :person_id, String
    end
  end
end
