ActiveSupport::Notifications.subscribe(/.*/) do |name, start, finish, id, payload|
  return unless Trace.tracing?
  c = AbsoluteTime.now

  t = Trace.new(name, payload)
  t.finish = c
  t.start = c - (finish - start) #throw away the Time objects for our absolute time.
  t.after
end
