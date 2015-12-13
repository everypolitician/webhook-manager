Sequel.migration do
  change do
    drop_table :updates
    drop_table :submissions
  end
end
