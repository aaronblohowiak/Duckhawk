Trace.trace_complete = Proc.new do |t|
  puts t.to_hash
end

Trace.trace('foo') do
  sleep 0.01
  Trace.trace('bar') do
    sleep 0.02
  end

  Trace.trace('bar') do
    sleep 0.02

    Trace.trace('baz') do
      sleep 0.01
    end
  end

  Trace.trace('foo') do
    sleep 0.2
  end
end

require 'json'
require 'benchmark'

JSON.singleton_class.extend AddToMethod
JSON.singleton_class.add_to_method :parse, :benchmark do |old_method, new_method|
  define_method(new_method) do |*args, &block|
    result = nil; bm = Benchmark.measure{
      result = send(old_method, *args, &block)
    }
    puts bm; result
  end
end

JSON.parse("{}")
