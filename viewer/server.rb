require 'open-uri'
require 'webrick'
require 'json'

class NonCachingFileHandler < WEBrick::HTTPServlet::FileHandler
  def prevent_caching(res)
    res['ETag']          = nil
    res['Last-Modified'] = Time.now + 100**4
    res['Cache-Control'] = 'no-store, no-cache, must-revalidate, post-check=0, pre-check=0'
    res['Pragma']        = 'no-cache'
    res['Expires']       = Time.now - 100**4
  end

  def do_GET(req, res)
    super
    prevent_caching(res)
  end

end

require 'net/http'
def get_elasticsearch(id)
  begin
    uri = URI.parse(ENV['ES_URL'])
  rescue
    return []
  end

  body = JSON.dump({
    "query" => {
      "filtered"=> {
        "filter"=> {
          "fquery"=> {
            "query"=> {
              "query_string" => {
                "query"=> "root_id:\""+id+"\""
              }
            }
          }
        }
      }
    },
    "size" => 10000
  })

  uri_without_basic_auth = uri.scheme+"://"+uri.host+uri.path
  post =  Net::HTTP::Post.new(uri_without_basic_auth)


  post['Content-Type'] = 'application/json'
  post.body = body
  post.basic_auth(uri.user, uri.password)

  http = Net::HTTP.new(uri.hostname, uri.port)
  http.use_ssl = true
  res = http.start do |http|
    http.request(post)
  end

  JSON.load(res.body)['hits']['hits'].map{|h| h['_source']}
end

def get_scalyr(id, continuation_token = nil)
  begin
    uri = ENV['SCALYR_URL'] + URI.escape("$root_id = '"+id+"'")
    uri += '&' + URI.escape("continuationToken=#{continuation_token}") if !continuation_token.nil?

    raw = JSON.load(open(uri).read)

    result = raw["matches"].map{|m| JSON.load(m["message"].match(/\{.*$/)[0].strip) }
    continuation_token = raw['continuationToken']

    if raw['matches'].size > 0 && !continuation_token.nil?
      result += get_scalyr(id, continuation_token)
    end

    return result
  rescue => e
    puts "Could not load from scalyr: #{e.message}"
    return []
  end
end


require 'json'

require 'redis' rescue nil
@trace_redis = Redis.connect rescue nil

def get_redis(id)
  return [] unless @trace_redis
  @trace_redis.lrange("trace::#{id}", 0, -1).map{|t| JSON.load(t)}
end


server = WEBrick::HTTPServer.new :Port => 1337
server.mount "/", NonCachingFileHandler, File.dirname(__FILE__)+"/static"

server.mount_proc '/data' do |req, res|
  id = req.query["id"]
  res.body = JSON.dump(get_redis(id) + get_elasticsearch(id)+ get_scalyr(id))
end

trap('INT') { server.stop }
server.start

