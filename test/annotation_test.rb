require_relative 'test_helper'

class TestAnnotation < Minitest::Test
  def setup
    @traces = []
    Trace.trace_complete = Proc.new{|t| @traces << t}
    Trace.root_id = Trace.new_id
    Trace.enable_tracing!
  end

  def trace_with_annotate
    Trace.trace('hello'){ Trace.annotate(kitten: :cute)}
  end

  def test_annotate
    trace_with_annotate    
    assert_equal :cute, @traces.first.payload[:kitten]
  end

  def test_annotate_when_not_tracing
    assert_equal @traces, []
    Trace.disable_tracing!
    trace_with_annotate
    assert_equal @traces, []
  end
end
