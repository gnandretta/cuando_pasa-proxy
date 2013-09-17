require 'sinatra'
require 'sass'
require 'cuando_pasa/proxy'

include CuandoPasa::Proxy

configure do
  DB.start(ENV.fetch("DATABASE_URL"))
  Thread.new do
    loop do
      SessionCookie.refresh
      sleep(5 * 60) # every 5 minutes
    end
  end
end

get '/style.css' do
  scss :style, style: :compressed
end

get '/' do
  erb :index
end

get '/arrivals' do
  @arrivals = Arrival.query(params[:bus_stop_id].strip.to_i)
  erb :arrivals
end

get '/stops' do
  @stops = Stop.near(params[:location].map(&:to_f)).limit(15)
  erb :stops, layout: false
end
