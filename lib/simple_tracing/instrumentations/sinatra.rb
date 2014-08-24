Sinatra::Templates.wrap_around_method :render, :trace do |old_method, new_method|
  define_method new_method do |*args, &block|
    Trace.trace "sinatra.template.render", :engine => args[0], :template => args[1] do
      send(old_method, *args, &block)
    end
  end
end
