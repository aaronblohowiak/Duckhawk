# With code from https://github.com/stevebartholomew/newrelic_moped/blob/master/LICENSE

Moped::Node.class_eval do
  def logging_with_trace(operations, &blk)
    operation_name, collection = determine_operation_and_collection(operations.first)
    log_statement = operations.first.log_inspect.encode("UTF-8")

    operation = case operation_name
             when 'INSERT', 'UPDATE', 'CREATE', 'FIND_AND_MODIFY'  then 'save'
             when 'QUERY', 'COUNT', 'GET_MORE', 'AGGREGATE'        then 'find'
             when 'DELETE'                                         then 'destroy'
             else
               nil
             end

    command = Proc.new { logging_without_trace(operations, &blk) }

    res = if operation
      metric = "moped/#{collection}/#{operation}"
      Trace.trace(metric, {log: log_statement}) do
        command.call
      end
    else
      Trace.trace('moped', {log: log_statement}) do
        command.call
      end
    end

    res
  end

  def determine_operation_and_collection(operation)
    log_statement = operation.log_inspect.encode("UTF-8")
    collection = "Unknown"
    if operation.respond_to?(:collection)
      collection = operation.collection
    end
    operation_name = log_statement.split[0]
    if operation_name == 'COMMAND' && log_statement.include?(":mapreduce")
      operation_name = 'MAPREDUCE'
      collection = log_statement[/:mapreduce=>"([^"]+)/,1]
    elsif operation_name == 'COMMAND' && log_statement.include?(":count")
      operation_name = 'COUNT'
      collection = log_statement[/:count=>"([^"]+)/,1]
    elsif operation_name == 'COMMAND' && log_statement.include?(":aggregate")
      operation_name = 'AGGREGATE'
      collection = log_statement[/:aggregate=>"([^"]+)/,1]
    elsif operation_name == 'COMMAND' && log_statement.include?(":findAndModify")
      operation_name = 'FIND_AND_MODIFY'
      collection = log_statement[/:findAndModify=>"([^"]+)/,1]
    end
    return operation_name, collection
  end

  alias_method :logging_without_trace, :logging
  alias_method :logging, :logging_with_trace
end
