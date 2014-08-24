ActiveSupport::Notifications.subscribe(/.*/) do |name, start, finish, id, payload|
  return unless Trace.tracing?

  #TODO: revamp this.
  return

  if Trace.trace_context
    c = AbsoluteTime.now
    t = Trace.new(name)
    t.payload = payload
    t.finish = c
    t.start = c - (finish - start)
  end
end
