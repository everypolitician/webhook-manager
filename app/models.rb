# http://sequel.jeremyevans.net/rdoc-plugins/files/lib/sequel/extensions/connection_validator_rb.html
Sinatra::Application.database.extension(:connection_validator)
Sinatra::Application.database.pool.connection_validation_timeout = -1

Sequel::Model.plugin :timestamps
Sequel::Model.plugin :validation_helpers
Sequel::Model.plugin :json_serializer

require 'app/models/user'
require 'app/models/application'
