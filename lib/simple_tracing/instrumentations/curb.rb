# Curb always uses a multi, even for single requests
Curl::Multi.wrap_around_method :perform, :trace do |old_method, new_method|
  define_method new_method do |*args, &block|
    return send(old_method, *args, &block) unless Trace.tracing?

    t = Trace.new :'http.curb.multi'

    requests_for_timing = [].concat self.requests
    child_traces = []
    requests_for_timing.each do |req|
      child_trace = Trace.new('http.curb.multi.child', {
        :'url' => req.url.to_s,
        :'original_options' => {
            :body => req.post_body
        }})
      child_traces << child_trace

      req.headers[:'X-Trace-Root-ID'] = Trace.root_id
      req.headers[:'X-Trace-Parent-ID'] = child_trace.id
    end
      

    t.start = AbsoluteTime.now
    t.before
    tracing_result = send(old_method, *args, &block)
    t.finish = AbsoluteTime.now

    requests_for_timing.each_with_index do |request, index|
      child_t = child_traces[index]
      child_t.payload[:'response_code'] =  request.response_code

      child_t.payload[:total_time] = request.total_time
      child_t.payload[:name_lookup_time] = request.name_lookup_time
      child_t.payload[:connect_time] = request.connect_time
      child_t.payload[:pre_transfer_time] = request.pre_transfer_time
      child_t.payload[:start_transfer_time] = request.start_transfer_time
      child_t.payload[:redirect_time] = request.redirect_time

      child_t.before
      child_t.start = t.start
      child_t.finish = t.start + child_t.payload['total_time'].to_f
      child_t.after
    end

    t.after

    tracing_result
  end
end
