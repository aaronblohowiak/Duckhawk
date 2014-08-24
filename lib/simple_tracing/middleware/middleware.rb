#Rack middleware
# TODO: make all the strings in this file configurable!
class Trace::Middleware
  attr_reader :app
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    
    trace_id = env['HTTP_X_TRACE_ROOT_ID'] || request['trace_root_id']
    if trace_id || request.params['please_trace'].nil?
      Trace.disable_tracing!
      return @app.call(env)
    end
    Trace.enable_tracing!

    Trace.root_id = trace_id || Trace.new_id

    puts "Tracing #{Trace.root_id} #{request.uri} #{request.user_agent}"

    parent_id = env['HTTP_X_TRACE_PARENT_ID'] || request['trace_parent_id']
    payload = {
      request:{
        path: request.path,
        host: request.host,
        method: request.request_method
      }
    }

    status, headers, response = nil
    Trace.trace('middleware', payload) do
      status, headers, response = @app.call(env)
    end

    headers['X-TRACE-ID'] = Trace.root_id
    [status, headers, response]
  end
end
