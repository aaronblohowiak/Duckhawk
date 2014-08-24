require 'multijson'

[:load, :dump].each do |method_name|
  MultiJson.wrap_around_method method_name, :trace do |old_method, new_method|
    trace_name = :"multi_json.#{method_name}"
    define_method method_name do |*args, &block|
      Trace.trace trace_name do
        send(old_method, *args, &block)
      end
    end
  end
end