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

  #global context
  @@tracing = false
  @@trace_context = nil
  @@root = nil

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
        pid: pid
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
    return unless @@complete_handler
    begin
      Trace.disable_tracing!
      @@complete_handler.call(self)
    rescue => e
      $stderr.puts "Could not handle trace completion. #{e.message} #{e.backtrace}"
    ensure
      Trace.enable_tracing!
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

## Global context
  def self.trace_context=(t)
    @@trace_context = t
  end

  def self.trace_context
    @@trace_context
  end

  def self.root_id
    @@root_id ||= self.new_id
  end

  def self.epoch_for_monotonic(mono)
    @@root_time_wall + (mono - @@root_time_monotonic)
  end

  def self.root_id=(id)
    @@root_id = id
    #when we change roots, lets also update our walltime. within this root,
    #  we will fake walltime by adding the delta of the monotonic.
    #  this is more accurate for comparing durations within this procss and faster.
    @@root_time_wall = Time.now.to_f
    @@root_time_monotonic = AbsoluteTime.now
    @@root_id
  end

  def self.trace_complete=(proc)
    @@complete_handler = proc
  end

# Turning tracing on and off
  def self.enable_tracing!
    @@tracing = true
  end

  def self.disable_tracing!
    @@tracing = false
  end

  def self.tracing?
    @@tracing
  end

  def self.hostname
    @@hostname ||= (`hostname`.strip rescue 'unknwon-host')
  end
end

