Typhoeus::Request.wrap_around_method :run, :trace do |old_method, new_method|
  define_method new_method do |*args, &block|
    return send(old_method, *args, &block) unless Trace.tracing?

    t = Trace.new("http.typhoeus")
    t.before
    t.start = AbsoluteTime.now

    tracing_result = send(old_method, *args, &block)

    t.finish = AbsoluteTime.now

    t.payload.merge!({
      :'url' => self.url.to_s,
      :'User-Agent' => $user_agent,
      :'original_options' => self.original_options
    })

    self.original_options[:headers] ||={}

    self.options[:headers]['X-Trace-Root-ID'] = Trace.root_id
    self.options[:headers]['X-Trace-Parent-ID'] = t.id

    if $trace_config[:backtraces]
      t.payload[:backtrace] = caller().select{|s| s =~/#{$trace_config[:backtrace_filter]}/ } 
    end

    timing_hack_options = tracing_result.options
    typhoeus_timing_info = timing_hack_options.keys.each do |key|
      if key =~ /time/
        t.payload[key] = timing_hack_options[key]
      end
    end

    t.after
    tracing_result 
  end
end

Typhoeus::Hydra.wrap_around_method :run, :trace do |old_method, new_method|
  define_method new_method do |*args, &block|
    return send(old_method, *args, &block) unless Trace.tracing?

    t = Trace.new("http.typhoeus.hydra")

    #make a copy because Typhoeus modifies this in-place
    requests_for_timing = [].concat self.queued_requests

    child_traces = []

    requests_for_timing.each do |req|
      child_trace = Trace.new('http.typhoeus.hydra.child', {
        :'url' => req.url.to_s,
        :'User-Agent' => $user_agent, #TODO: remove this global
        :'original_options' => req.original_options})
      child_traces << child_trace

      req.options[:headers]['X-Trace-Root-ID'] = Trace.root_id
      req.options[:headers]['X-Trace-Parent-ID'] = child_trace.id
    end

    t.start = AbsoluteTime.now
    t.before
    tracing_result = send(old_method, *args, &block)

    t.finish = AbsoluteTime.now

    #for each request in requests_for_timing, create a new trace
    requests_for_timing.each_with_index do |request, index|
      child_t = child_traces[index]
      child_t.payload[:'response_code'] =  request.response.options[:response_code]

      request.response.options.keys.each do |key|
        if key.to_s =~ /time/
          child_t.payload[key.to_s] = request.response.options[key]
        end
      end
    
      child_t.before
      child_t.start = t.start
      child_t.finish = t.start + child_t.payload['total_time'].to_f
      child_t.after
    end

    t.after

    tracing_result
  end
end
