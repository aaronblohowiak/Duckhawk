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

def get_elasticsearch
  @example ||= JSON.dump(JSON.load(File.read(File.dirname(__FILE__)+"/../data.json"))['hits']['hits'].map{|h| h['_source']})
end


server = WEBrick::HTTPServer.new :Port => 1337
server.mount "/", NonCachingFileHandler, File.dirname(__FILE__)+"/static"

server.mount_proc '/data' do |req, res|
  res.body = get_elasticsearch()
end

trap('INT') { server.stop }
server.start

