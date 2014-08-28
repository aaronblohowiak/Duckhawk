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
    t.start = AbsoluteTime.now
    result = nil
    begin
      result = send(old_method, *args, &block)
      t.finish = AbsoluteTime.now
      t.after
      return result
    rescue => e
      t.finish = AbsoluteTime.now
      t.after
      raise e
    end
  end
end
