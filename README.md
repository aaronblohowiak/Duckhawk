simple-tracing
========

DB:

    Done: Redis, MongoMapper (mongo-ruby-driver 1.x), ActiveRecord (active_support/notifications)
    TODO: Mongoid

HTTP:

    Done: Curb, Typhoeus, Faraday*, Net::HTTP (httparty, rest-client)
    TODO: httpclient,  Patron
    WONT: em*

Notifications:

    Done: active_support/notifications
    TODO: Airbrake

Web Frameworks:

    Done: Sinatra
    TODO: Rails

Config
=============

    TODO: trace init param name, header names, frequency of initiations, mode (all/through/percentage/none)
    DONE: trace_complete= Proc{|t| t.to_json }


HOWTO: Backtraces.
==============

  Trace.trace_complete= Proc do |t|
    hsh = t.to_hash
    if hsh[:duration] > 0.05 #50ms
      hsh[:payload][:backtrace] = caller() // you probably want to filter this array of file:line strings
    end

    puts hsh.to_json #send it somewhere useful!
  end


HOWTO: Use in terminal
==============

Trace.enable_tracing!
Trace.root_id=Trace.new_id
Trace.trace_complete=Proc.new{|t| puts t.to_json}

