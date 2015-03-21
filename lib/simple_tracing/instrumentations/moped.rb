#support older moped 1.5, so we cant use the builtin instrumenter stuff, in a simple way.
Moped::Node.wrap_around_method :logging, :trace do |old_method, new_method|
  define_method new_method do |*args, &block|
    Trace.trace "moped", :args => args do
      send(old_method, *args, &block)
    end
  end
end
