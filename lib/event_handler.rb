# Takes a github webhood event and payload and dispatches to registered classes
class EventHandler
  def self.register_handler(github_event, klass)
    @handlers ||= {}
    github_event = github_event.to_sym
    @handlers[github_event] ||= []
    @handlers[github_event] << klass
    @handlers
  end

  def self.handle(github_event, payload)
    classes = @handlers[github_event.to_sym]
    return "Unknown event type: #{github_event}" unless classes
    classes.each do |klass|
      klass.perform_async(payload)
    end
    classes.map(&:to_s).join(', ') + ' queued'
  end
end
