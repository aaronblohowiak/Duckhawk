require 'benchmark'

require 'absolute_time'

class Trace
  attr_accessor :id, :children, :parent, :payload, :tag, :start, :finish, :gc_start, :gc_finish

  #root-node-only attrs
  attr_accessor :start_wall, :end_wall

  @@id = 0
  @@trace_context = nil


  @@include_backtrace = RUBY_VERSION =~ /^2/

  def initialize(tag, payload = nil)
    self.tag = tag
    self.children = []
    self.id = (@@id += 1)
    self.parent = parent
    self.payload = payload
  end

  def to_hash
    hsh = {}

    if start_wall
      hsh.merge!({
        start_wall: start_wall,
        end_wall: end_wall
      })
    end

    hsh.merge!({
      tag: tag,
      id: id,
      start: start,
      finish: finish,
      gc_start: gc_start,
      gc_finish: gc_finish,
      payload: (payload && payload.to_hash),
      children: children.map(&:to_hash)
    })

    hsh
  end

  def self.trace(tag, payload=nil, id=nil)
    begin
      old_trace_context = self.trace_context
      t = self.new(tag)
      t.id = id if id
      t.payload = payload || {}

      if @@include_backtrace
        t.payload.merge!({backtrace: caller(1, 10)})
      end

      t.parent = old_trace_context
      if old_trace_context
        old_trace_context.children << t
      else
        t.start_wall = Time.now.strftime("%Y-%m-%d %H:%M:%S.%5N %z")
      end
      self.trace_context = t

      result = nil
      t.gc_start = GC.count
      t.start = AbsoluteTime.now
      yield
    ensure
      t.finish = AbsoluteTime.now
      t.gc_finish = GC.count
      if old_trace_context.nil?
        t.end_wall = Time.now.strftime("%Y-%m-%d %H:%M:%S.%5N %z")
      end
      self.trace_context = old_trace_context
    end
  end

  def self.trace_context
    @@trace_context
  end

  def self.trace_context=(root)
    puts "setting context: #{root.inspect}"
    if root.nil?
      @@id = 0
      if @@complete_handler
        @@complete_handler.call(@@trace_context)
      end
    end
    @@trace_context = root
  end

  def self.trace_complete=(proc)
    @@complete_handler = proc
  end
end
