#Rack middleware
# TODO: make all the strings in this file configurable!
class Trace::Middleware
  attr_reader :app
  def initialize(app)
    @app = app
  end

  def call(env)
    Trace.reset_thread_state!

    request = Rack::Request.new(env)

    trace_id = env['HTTP_X_TRACE_ROOT_ID'] || request['trace_root_id']
    trace_id = nil if trace_id == ""
    if trace_id.nil? && request.params['please_trace'].nil?
      Trace.without_tracing do
        return @app.call(env)
      end
    end

    Trace.with_tracing do
      Trace.root_id = trace_id || Trace.new_id
      headers['X-TRACE-ID'] = Trace.root_id

      parent_id = env['HTTP_X_TRACE_PARENT_ID'] || request['trace_parent_id']

      puts "Tracing Enabled. #{Trace.root_id}::#{parent_id || "no-parent"} #{request.url} #{request.user_agent}"
      payload = {
        request:{
          path: request.path,
          host: request.host,
          method: request.request_method,
          agent: request.user_agent,
        },
        parent_id: parent_id
      }

      status, headers, response = nil
      Trace.trace('middleware', payload) do
        status, headers, response = @app.call(env)
      end

      return [status, headers, response]
    end
  end
end
