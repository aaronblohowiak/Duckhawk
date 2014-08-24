require 'sinatra'
require 'redis'


set :public_folder, File.dirname(__FILE__) + '/static'
get '/' do
  redirect_to 'index.html'
end


$r = Redis.new

