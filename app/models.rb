Sequel::Model.plugin :timestamps
Sequel::Model.plugin :validation_helpers
Sequel::Model.plugin :json_serializer

require 'app/models/user'
require 'app/models/application'
require 'app/models/submission'
require 'app/models/updates'
