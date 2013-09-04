require 'sinatra'

require 'redis'
require 'ohm'
require 'ohm/contrib'

require 'json/ext'


require_relative './lib/add_to_method'
require_relative './lib/trace'

Ohm.connect

$r = Redis.new

class TraceRecord < Ohm::Model
  include Ohm::DataTypes

  attribute :trace, Type::Hash
end

get '/' do
  content_type :json
  Trace.trace 'get /' do
    JSON.dump(TraceRecord[$r.lindex 'traces', 0].trace)
  end
end

Module.send :include, AddToMethod

Redis.instance_methods(false).each do |name|
  Redis.add_to_method name, :trace do |old_method, new_method|
    define_method new_method do |*args, &block|
      Trace.trace "redis.#{name}", :key => args[0] do
        send(old_method, *args, &block)
      end
    end
  end
end

Ohm::Model.add_to_method :load!, :ohm_load do |old_method, new_method|
  define_method new_method do |*args, &block|
    Trace.trace :'ohm.load' do
      send(old_method, *args, &block)
    end
  end
end

[:dump, :load, :generate, :[]].each do |name|
JSON.singleton_class.add_to_method name, :trace do |old_method, new_method|
  define_method new_method do |*args, &block|
      Trace.trace "JSON.#{name}" do
        send(old_method, *args, &block)
      end
    end
  end
end

Hash.add_to_method :to_json, :trace do |old_method, new_method|
  define_method new_method do |*args, &block|
    Trace.trace 'hash.to_json' do
      send(old_method, *args, &block)
    end
  end
end

Trace.trace_complete = Proc.new do |t|
  r = TraceRecord.create(trace: t.to_hash)
  $r.lpush 'traces', r.id
  puts t.to_hash
end

set :public_folder, File.dirname(__FILE__) + '/static'
