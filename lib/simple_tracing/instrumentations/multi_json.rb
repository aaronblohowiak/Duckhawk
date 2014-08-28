require 'multi_json'

class << MultiJson
  alias_method :load_without_tracing_for_Trace, :load

  def load(*args)
    return load_without_tracing_for_Trace(*args) unless Trace.tracing?

    Trace.trace 'json.multi.load' do
      load_without_tracing_for_Trace(*args)
    end
  end

  alias_method :dump_without_tracing_for_Trace, :dump

  def dump(*args)
    return dump_without_tracing_for_Trace(*args) unless Trace.tracing?

    Trace.trace 'json.multi.load' do
      dump_without_tracing_for_Trace(*args)
    end
  end

  #trace the aliases as well
  def encode(*args)
    dump(*args)
  end

  #trace the aliases as well
  def decode(*args)
    load(*args)
  end
end
