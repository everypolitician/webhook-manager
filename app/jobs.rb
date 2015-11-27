# Lots of the background jobs run 'bundle install' in the everypolitician-data
# repo. This can be very slow because nokogiri compiles it's own versions of
# libxml and libxslt. Setting this environment variable should speed up the builds.
ENV['NOKOGIRI_USE_SYSTEM_LIBRARIES'] = '1'

require 'app/jobs/merge_job'
require 'app/jobs/accept_submission_job'
require 'app/jobs/deploy_viewer_sinatra_pull_request_job'
require 'app/jobs/handle_everypolitician_data_pull_request_job'
require 'app/jobs/send_webhook_job'
