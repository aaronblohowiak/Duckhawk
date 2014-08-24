[:get, :post, :delete, :put].each do |http_method|
  tracename = "faraday.#{http_method}"
  Faraday::Connection.wrap_around_method http_method, :trace do |old_method, new_method|
    define_method new_method do |*args, &block|
      Trace.trace tracename do
        send(old_method, *args, &block)
      end
    end
  end
end
