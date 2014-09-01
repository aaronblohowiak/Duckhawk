require 'net/http'

Net::HTTP.wrap_around_method :request, :trace do |old_method, new_method|
  with_uri = Net::HTTP.respond_to? :uri

  define_method new_method do |*args, &block|
    return send(old_method, *args, &block) unless Trace.tracing?

    req = args[0]
    payload = {:method => req.method, :path => req.path, :host => self.address}
    if with_uri
      payload[:uri] = uri.to_s
    end

    t = Trace.new('http.net', payload)
    req['X-Trace-Root-ID'] = Trace.root_id
    req['X-Trace-Parent-ID'] = t.id

    t.before
    result = nil
    t.start = AbsoluteTime.now
    begin
      result = send(old_method, *args, &block)
    else
      t.finish = AbsoluteTime.now
      return result
    ensure
      t.finish ||= AbsoluteTime.now
      t.after
    end
  end
end
