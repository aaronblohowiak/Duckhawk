ActiveSupport::Notifications.subscribe(/.*/) do |name, start, finish, id, payload|
  if Trace.tracing? #can't return cause we are in a block ;)
    c = AbsoluteTime.now

    t = Trace.new(name, payload)
    t.before
    t.finish = c
    t.start = c - (finish - start) #throw away the Time objects for our absolute time.
    t.after
  end
end
