Sequel.migration do
  change do
    alter_table(:applications) do
      add_column :pull_request_opened, FalseClass, null: false, default: true
      add_column :pull_request_synchronize, FalseClass, null: false, default: true
      add_column :pull_request_closed, FalseClass, null: false, default: true
      add_column :pull_request_merged, FalseClass, null: false, default: true
    end

    # Only send merge events to existing apps to preserve backwards compatibility
    from(:applications).update(
      pull_request_opened: false,
      pull_request_synchronize: false,
      pull_request_closed: false
    )
  end
end
