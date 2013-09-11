require 'sinatra'
require 'sass'
require 'cuando_pasa/proxy'

include CuandoPasa::Proxy

configure do
  DB.start(ENV.fetch("DATABASE_URL"))
end

get '/style.css' do
  scss :style, style: :compressed
end

get '/' do
  erb :index
end

get '/arrivals' do
  @arrivals = Arrival.query(params[:bus_stop_id])
  erb :arrivals
end
