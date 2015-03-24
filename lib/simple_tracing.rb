$trace_config ||= {}

require 'securerandom'
require 'absolute_time'

#blow up if WrapMethod is already defined or if Module.respond_to? wrap_around_method
module WrapMethod
 def wrap_around_method(method, name, &wrapper)
    method_name_without_feature = :"#{method}_for_#{name}_on_#{self.name}_without_#{name}"
    method_name_with_feature = :"#{method}_for_#{name}_on_#{self.name}_with_#{name}"

    raise ArgumentError, "already added #{method} for #{name} on #{self.name}" if method_defined? method_name_without_feature
    raise ArgumentError, "could not find method #{method} for #{self.name}" unless method_defined?(method) || private_method_defined?(method)

    alias_method method_name_without_feature, method
    instance_exec method_name_without_feature, method_name_with_feature, &wrapper
    alias_method method, method_name_with_feature
  end
end
Module.send :include, WrapMethod

class Trace
  attr_accessor :id, :parent_id, :root_id
  attr_accessor :tag, :payload,  :start, :finish, :gc_start, :gc_finish

  attr_accessor :old_trace_context

  #root-node-only attrs
  attr_accessor :host, :pid

  def initialize(tag, payload = {})
    self.tag = tag
    self.id = Trace.new_id
    self.payload = payload
    self.parent_id = payload[:parent_id]
    self.root_id = Trace.root_id
    self
  end

  def to_hash
    hsh = {}

    if host
      hsh.merge!({
        host: host,
        pid: pid,
        service: @@service_name
      })
    end

    hsh.merge!({
      tag: tag,
      id: id,
      parent_id: parent_id,
      root_id: root_id,
      start: start,
      finish: finish,
      duration: finish-start,
      gc_start: gc_start,
      gc_finish: gc_finish,
      payload: (payload && payload.to_hash)
    })
  end

  def before
    self.old_trace_context = Trace.trace_context
    self.parent_id ||= old_trace_context && old_trace_context.id
    Trace.trace_context = self
    self.gc_start = GC.count

    if !old_trace_context
      GC::Profiler.clear
      GC::Profiler.enable
      self.host = Trace.hostname
      self.pid = ::Process.pid
    end
  end

  def after
    if !self.old_trace_context
      self.payload[:gc_stat] = GC.stat
      self.payload[:gc_profiler] = GC::Profiler.result
      self.payload[:gc_totaltime] = GC::Profiler.total_time
      GC::Profiler.disable
      GC::Profiler.clear
    end

    self.gc_finish = GC.count
    self.start = Trace.epoch_for_monotonic(self.start)
    self.finish = Trace.epoch_for_monotonic(self.finish)
    notify_complete!
    Trace.trace_context = self.old_trace_context
  end

  def notify_complete!
    if !@@complete_handler
      $stderr.puts "Could not handle trace completion because there is no completion handler."
      return
    end

    begin
      Trace.without_tracing do
        @@complete_handler.call(self)
      end
    rescue => e
      $stderr.puts "Could not handle trace completion. #{e.message} #{e.backtrace}"
    end
  end

  def self.reset_thread_state!
    Thread.current[:simple_trace_context] = nil
    Thread.current[:simple_tracing_enabled] = nil
    Thread.current[:simple_trace_root_id] = nil
  end

  def self.without_tracing
    Thread.current[:simple_tracing_enabled] ||= []
    Thread.current[:simple_tracing_enabled].push(false)
    begin
      yield
    ensure
      Thread.current[:simple_tracing_enabled].pop
    end
  end

  def self.with_tracing
    begin
      Thread.current[:simple_tracing_enabled] ||= []
      Thread.current[:simple_tracing_enabled].push(true)
      yield
    ensure
      Thread.current[:simple_tracing_enabled].pop
    end
  end

  def self.new_id
    SecureRandom.urlsafe_base64
  end

  def self.trace(tag, payload={})
    return yield if !tracing?

    t = self.new(tag, payload)
    begin
      #TODO: There may be an issue with throw/catch at the moment. The `ensure` might be swallowing them. need to look into it.
      t.before
      t.start = AbsoluteTime.now
      yield
    ensure
      t.finish = AbsoluteTime.now
      t.after
    end
  end

  class << self
    alias_method :instrument, :trace
  end

  def self.annotate(payload)
    return unless self.trace_context
    self.trace_context.payload.merge!(payload)
  end

## thread-local context
  def self.trace_context=(t)
    Thread.current[:simple_trace_context] = t
  end

  def self.trace_context
    Thread.current[:simple_trace_context]
  end

  def self.root_id
    Thread.current[:simple_trace_root_id]
  end

  def self.tracing?
    Thread.current[:simple_tracing_enabled] && Thread.current[:simple_tracing_enabled].last
  end

  def self.root_id=(id)
    Thread.current[:simple_trace_root_id] = id
    #when we change roots, lets also update our walltime. within this root,
    #  we will fake walltime by adding the delta of the monotonic.
    #  this is more accurate for comparing durations within this procss and faster.
    @@root_time_wall = Time.now.to_f
    @@root_time_monotonic = AbsoluteTime.now
    Thread.current[:simple_trace_root_id]
  end

#Globally stateful
  def self.epoch_for_monotonic(mono)
    return nil unless mono && @@root_time_monotonic
    @@root_time_wall + (mono - @@root_time_monotonic)
  end

  #global! Expected that this will be written once
  def self.service_name=(string)
    @@service_name = string
  end
  @@service_name = nil

  #global! Expected that this will be written once
  def self.trace_complete=(proc)
    @@complete_handler = proc
  end

  def self.hostname
    @@hostname ||= (`hostname`.strip rescue 'unknwon-host')
  end

#Deprecated
  def self.enable_tracing!
    raise "Unsupported. Use Trace.with_tracing do..end"
  end

  def self.disable_tracing!
    raise "Unsupported. Use Trace.without_tracing do..end"
  end
end

