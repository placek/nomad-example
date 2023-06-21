require 'sinatra'
require 'redis'

configure do
  set :redis, Redis.new(url: ENV['REDIS_URL'])
end

get '/' do
  'app is OK'
end

get '/:key' do
  settings.redis.get(params['key'])
end
