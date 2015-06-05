DB = Sequel.connect(ENV['DATABASE_URL'], encoding: 'utf-8')

Sequel::Model.plugin :timestamps

require 'app/models/user'
