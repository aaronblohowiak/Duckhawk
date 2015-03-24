require_relative 'test_helper'

class TestAnnotation < Minitest::Test
  def setup
    @traces = []
    Trace.trace_complete = Proc.new{|t| @traces << t}
    Trace.root_id = Trace.new_id
  end

  def trace_with_annotate
    Trace.trace('hello'){ Trace.annotate(kitten: :cute)}
  end

  def test_annotate
    Trace.with_tracing do
      trace_with_annotate
    end
    assert_equal :cute, @traces.first.payload[:kitten]
  end

  def test_annotate_when_not_tracing
    assert_equal @traces, []
    Trace.without_tracing do
      trace_with_annotate
    end
    assert_equal @traces, []
  end
end
