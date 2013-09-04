module AddToMethod
 def add_to_method(method, name, &wrapper)
    method_name_without_feature = :"#{method}_for_#{name}_on_#{self.name}_without_#{name}"
    method_name_with_feature = :"#{method}_for_#{name}_on_#{self.name}_with_#{name}"

    raise ArgumentError, "already instrumented #{method} for #{name} on #{self.name}" if method_defined? method_name_without_feature
    raise ArgumentError, "could not find method #{method} for #{self.name}" unless method_defined?(method) || private_method_defined?(method)

    alias_method method_name_without_feature, method
    instance_exec method_name_without_feature, method_name_with_feature, &wrapper
    alias_method method, method_name_with_feature
  end
end

# require 'json'
# require 'benchmark'

# JSON.singleton_class.extend AddToMethod
# JSON.singleton_class.add_to_method :parse, :benchmark do |old_method, new_method|
#   define_method(new_method) do |*args, &block|
#     result = nil; bm = Benchmark.measure{
#       result = send(old_method, *args, &block)
#     }
#     puts bm; result
#   end
# end

# JSON.parse("{}")
