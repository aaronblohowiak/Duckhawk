[:dump, :load, :generate, :[]].each do |method_name|
  JSON.wrap_around_method method_name, :trace do |old_method, new_method|
    trace_name = :"JSON.#{method_name}"
    define_method method_name do |*args, &block|
      Trace.trace trace_name do
        send(old_method, *args, &block)
      end
    end
  end
end
