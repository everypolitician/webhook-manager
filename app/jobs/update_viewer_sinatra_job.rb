require 'datasource_update'

# Update viewer-sinatra repo with new countries from push event.
class UpdateViewerSinatraJob
  include Sidekiq::Worker

  attr_accessor :push

  def perform(push)
    @push = push
    DatasourceUpdate.new(push['after']).update if push_valid?
  end

  def push_valid?
    push_ref_is_master? && countries_json_pushed?
  end

  def push_ref_is_master?
    push['ref'] == 'refs/heads/master'
  end

  def countries_json_pushed?
    files = push['commits'].map do |commit|
      commit['added'] + commit['modified']
    end
    files.flatten.uniq.include?('countries.json')
  end
end
