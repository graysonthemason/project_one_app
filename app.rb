require 'sinatra/base'
require 'pry'
require_relative 'feed'
require 'redis'
require 'json'
require 'httparty'
require 'rss'
require 'uri'
require 'open-uri'
require 'rest_client'
require 'base64'
require_relative 'twitter'
require 'instagram'


class App < Sinatra::Base

  ########################
  # Configuration
  ########################

  configure do
    enable :logging
    enable :method_override
    enable :sessions
  end
    encoded = "alQwb28yc1d3eGNBVFVwWUh4bTZvTmJYQTp5WTF4VFF5NzN0UU12WnNPUW1HbVJsNGN4NWFtcTh5cnBCNnJ1NUF1aEQ5QWhnTDQ1RA0K"

    CALLBACK_URL = "http://localhost:9393/oauth/callback"





  before do
    logger.info "Request Headers: #{headers}"
    logger.warn "Params: #{params}"
  end

  after do
    logger.info "Response Headers: #{response.headers}"
  end
  ########################
  # Keys and ID's
  ########################

  Geo_API_Key = "5652d2f22aa2c9ef461c5bb22ce1fa20:0:69767276"
  Weather_API_Key = "11fb2f7f63a41afe"

  # OAUTH KEY
  # b0uFYe0GJuu7j79pYnKNwCazUS6xspexiPSQOkRb
  # OAUTH SECRET
  # C966S4tNnQj98uTfoq6mO91BF2BVbWqNFcGCkvVu


  #INSTAGRAM
  instagram_client_id = "89cf55f7701d4c869b495a1d3b06d41e"
  instagram_client_secret = "b157ba6549a54a9ab37192587871a9ea"

  access_token = "173753347.89cf55f.f1ed41f99d3c470d8613852411ba0646"

  ###TWITTER
  twitter_api_key =  "jT0oo2sWwxcATUpYHxm6oNbXA"
  twitter_api_secret = "yY1xTQy73tQMvZsOQmGmRl4cx5amq8yrpB6ru5AuhD9AhgL45D"

  twitter_access_token = "95246661-SOQsy4oZM6HgogQVCUwkeQ2UcvxFqhzrRbvrLm88H"
  twitter_access_token_secret = "jutb4vmi3HwBGujNGzjmgIfQHg7eqP9Vr1UacUxLbmf3O"

  twitter_bearer_token_credentials = "#{twitter_api_key}:#{twitter_api_secret}"
  twitter_base_encoded = "alQwb28yc1d3eGNBVFVwWUh4bTZvTmJYQTp5WTF4VFF5NzN0UU12WnNPUW1HbVJsNGN4NWFtcTh5cnBCNnJ1NUF1aEQ5QWhnTDQ1RA0K"
  # jT0oo2sWwxcATUpYHxm6oNbXA:yY1xTQy73tQMvZsOQmGmRl4cx5amq8yrpB6ru5AuhD9AhgL45D


  #TWITTER CREDENTIALS
  c_key = 'jT0oo2sWwxcATUpYHxm6oNbXA'
  c_secret = 'yY1xTQy73tQMvZsOQmGmRl4cx5amq8yrpB6ru5AuhD9AhgL45D'
  c_key_secret = "#{c_key}:#{c_secret}"
  encoded_c_key_secret = Base64.strict_encode64(c_key_secret)


  ########################
  # DB Configuration
  ########################
  $redis = Redis.new(:url => ENV["REDISTOGO_URL"])



Instagram.configure do |config|
  config.client_id = instagram_client_id
  config.client_secret = instagram_client_secret
  # For secured endpoints only
  #config.client_ips = '<Comma separated list of IPs>'
end

get "/oauth/connect" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
end

get "/oauth/callback" do
  response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
  session[:access_token] = response.access_token
  redirect "/profile"
end

  ########################
  # Methods
  ########################

  def most_common_hashtags(a)
    a.group_by do |e|
      e
    end.values.sort_by(&:size).flatten.uniq.last(5).reverse
  end

  ########################
  # Routes
  ########################

  get('/') do
    redirect to('/profile')
  end

  get('/feed') do

  end

  get('/snapshot') do
#retrieve geolocation
    nytimes_url = "http://api.nytimes.com/svc/semantic/v2/geocodes/query.json?&name=#{params[:keyword].gsub(' ', '+')}&country_name=#{params[:country].gsub(' ', '+')}&perpage=1&api-key=#{Geo_API_Key}"
# http://api.nytimes.com/svc/semantic/v2/geocodes/query.json?&name=Las+Vegas&country_name=United+States&api-key=####
    location = HTTParty.get(nytimes_url)
    @concept_name = location["results"][0]["concept_name"]
    @latitude = location["results"][0]["geocode"]["latitude"] 
    @longitude = location["results"][0]["geocode"]["longitude"] 
# retrieve weather
    base_url = "http://api.wunderground.com/api/#{Weather_API_Key}/conditions/q/"
    weather_url = "#{base_url}#{@latitude},#{@longitude}.json"
    weather = HTTParty.get(weather_url)
    @icon = weather["current_observation"]["icon"]
    @icon_url = weather["current_observation"]["icon_url"]
    @feels_like = weather["current_observation"]["feelslike_f"] 
    @temp = weather["current_observation"]["temp_f"]

#Twitter Authorize
    headers = 
    {
      'Authorization' => "Basic #{encoded_c_key_secret}", 
      'Content-Type'  => "application/x-www-form-urlencoded;charset=UTF-8"
    }
    body = 'grant_type=client_credentials'
    response = Twitter.post('/oauth2/token', :body => body, :headers => headers)
    bearer_token = response['access_token']
    headers = 
    {
      'Authorization' => "Bearer #{bearer_token}", 
      'Content-Type'  => "application/x-www-form-urlencoded;charset=UTF-8"
    }
#twitter get and manipulate data    
    get_woeid_url = "https://api.twitter.com/1.1/trends/closest.json?lat=#{@latitude}&long=#{@longitude}"
    woeid_results = Twitter.get(get_woeid_url, :headers => headers)
    woeid = woeid_results.to_a[0]["woeid"]
    trending_query = "https://api.twitter.com/1.1/trends/place.json?id=#{woeid}"
    @trending_results = Twitter.get(trending_query , :headers => headers)[0]["trends"]
#Instagram
    client = Instagram.client(:access_token => session[:access_token])
    results = client.media_search(@latitude,@longitude)
    @instagram_urls = []
    results.each do |result|
      @instagram_urls.push(result["images"]["low_resolution"]["url"])
    end
#redis set new feed object for user
    feed_hash = {
      "concept_name" => @concept_name,
      "latitude" => @latitude,
      "longitude" => @longitude,
      "icon" => @icon,
      "icon_url" => @icon_url,
      "feels_like" => @feels_like,
      "temp" => @temp,
      "instagram" => @instagram_urls,
      "trending_results" => @trending_results
    }
    Feed.new(feed_hash)
    redirect to('/snapshot/show')
  end
  get('/snapshot/show') do
    # string = $redis.get($redis.keys.sort[-2])
    @feed_hash = JSON.parse($redis.get($redis.keys.sort_by {|s| s[/\d+/].to_i}.last))
    # binding.pry
    @concept_name = @feed_hash["concept_name"]
    @latitude = @feed_hash["latitude"]
    @longitude = @feed_hash["longitude"]
    @icon_url = @feed_hash["icon_url"]
    @icon = @feed_hash["icon"]
    @feels_like = @feed_hash["feels_like"]
    @temp = @feed_hash["temp"]
    @instagram_urls = @feed_hash["instagram"]
    @trending_results = @feed_hash["trending_results"]
    render(:erb, :_snapshot, :layout => :layout)
  end
  get('/profile') do

    render(:erb, :profile, :layout => :layout)
  end
  delete('/profile/instagram/:id') do
    # binding.pry
    # current = JSON.parse($redis.get($redis.keys.sort[-2]))
    current_feed = JSON.parse($redis.get($redis.keys.sort_by {|s| s[/\d+/].to_i}.last))
    current_feed["instagram"].delete_at(params[:id].to_i)
    $redis.set("user:#{current_feed["id"]}", current_feed.to_json)
    redirect to ('/snapshot/show')
  end
end


