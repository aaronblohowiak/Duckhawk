Ohm::Model.wrap_around_method :load!, :trace do |old_method, new_method|
  define_method new_method do |*args, &block|
    Trace.trace :'ohm.load' do
      send(old_method, *args, &block)
    end
  end
end
