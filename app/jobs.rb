# Lots of the background jobs run 'bundle install' in the everypolitician-data
# repo. This can be very slow because nokogiri compiles it's own versions of
# libxml and libxslt. Setting this environment variable should speed up the builds.
ENV['NOKOGIRI_USE_SYSTEM_LIBRARIES'] = '1'

require 'app/jobs/send_webhook_job'
