require_relative 'test_helper'

class TestLifecycle < Minitest::Test
  def setup
    @traces = []
    Trace.trace_complete = Proc.new{|t| @traces << t}
  end

  def trace!
    Trace.trace('hello'){}
  end

  def test_tracing_enabled
    Trace.root_id = Trace.new_id
    Trace.enable_tracing!
    trace!
    assert_equal 'hello', @traces.first.tag
  end

  def test_tracing_disabled
    assert_equal @traces, []
    Trace.disable_tracing!
    trace!
    assert_equal @traces, []
  end

  def test_manual_tracing
    Trace.root_id = Trace.new_id
    Trace.enable_tracing!
    t = Trace.new('manual')
    t.before
    t.payload[:testing] = 123
    t.after
    output = @traces.first
    assert_equal 'manual', output.tag
    assert_equal 123, output.payload[:testing]
  end
end
