Sequel.migration do
  up do
    alter_table(:applications) do
      add_column :app_id, String, unique: true
    end
    applications = from(:applications)
    applications.all do |application|
      app_id = nil
      loop do
        app_id = SecureRandom.hex(10)
        break unless Application.where(app_id: app_id).any?
      end
      applications.where(id: application[:id]).update(app_id: app_id)
    end
    alter_table(:applications) do
      set_column_not_null :app_id
    end
  end

  down do
    alter_table(:applications) do
      drop_column :app_id
    end
  end
end
