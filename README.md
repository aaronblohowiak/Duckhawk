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
    return unless hsh[:duration] < 0.05 # skip unless at least 5 millis
    
    hsh[:payload][:backtrace] = caller() // you probably want to filter this array of file:line strings

    redis.multi do
      redis.lpush(hsh[:root_id], hsh.to_json) #send it somewhere useful!
      redis.setex(hsh[:root_id], 4.hours)
    end
  end


HOWTO: Use in terminal
==============

Trace.enable_tracing!
Trace.root_id=Trace.new_id
Trace.trace_complete=Proc.new{|t| puts t.to_json}


TODO before 0.2
==============
  Config
  Tests
  Service-Name

TODO before 1.0
==============
  Auto-load & Auto-detect
  Auto-install (Sinatra, Rails)?
