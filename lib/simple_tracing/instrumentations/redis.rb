Redis.instance_methods(false).each do |name|
  Redis.wrap_around_method name, :trace do |old_method, new_method|
    define_method new_method do |*args, &block|
      Trace.trace "redis.#{name}", :key => args[0] do
        send(old_method, *args, &block)
      end
    end
  end
end
