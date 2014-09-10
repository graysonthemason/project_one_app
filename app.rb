require 'sinatra/base'
require 'pry' if ENV["RACK_ENV"] == "development"
require_relative 'feed'
require 'redis'
require 'json'
require 'httparty'
require 'rss'
require 'uri'
require 'open-uri'
require 'rest_client'
require 'base64'
require_relative 'twitters'
require 'instagram'
require 'securerandom'
require 'jwt'
require 'tweetstream'


class App < Sinatra::Base

  ########################
  # Configuration
  ########################

  configure do
    enable :logging
    enable :method_override
    enable :sessions

  $redis = Redis.new(:url => ENV["REDISTOGO_URL"])

   
  end
  encoded = "alQwb28yc1d3eGNBVFVwWUh4bTZvTmJYQTp5WTF4VFF5NzN0UU12WnNPUW1HbVJsNGN4NWFtcTh5cnBCNnJ1NUF1aEQ5QWhnTDQ1RA0K"
  $current_feed_id = ""
  

#GOOGLE SIGN IN
    CLIENT_ID_GOOGLE = "381692329282-fft9jv4jfig202c13k6ajuklm0d1ev1u.apps.googleusercontent.com"
    EMAIL_ADDRESS_GOOGLE = "381692329282-fft9jv4jfig202c13k6ajuklm0d1ev1u@developer.gserviceaccount.com"
    CLIENT_SECRET_GOOGLE = "XAlp1T20f1C_yNDidn50O5ZQ"
   
    # JAVASCRIPT_ORIGINS = "http://127.0.0.1:9292"
  if ENV["RACK_ENV"] == "development"
    WEBSITE_URL = "http://localhost:9292"
    CALLBACK_URL = "http://localhost:9292/oauth/callback"
    REDIRECT_URI = "http://localhost:9292/Oauth"
    JAVASCRIPT_ORIGINS = "http://localhost:9292m/"
    REDIRECT_URIS_GOOGLE = "http://localhost:9292/oauth2callback"
  else
    REDIRECT_URIS_GOOGLE = "http://glacial-fjord-8454.herokuapp.com/oauth2callback"
    CALLBACK_URL = "http://glacial-fjord-8454.herokuapp.com/oauth/callback"
    WEBSITE_URL = "http://glacial-fjord-8454.herokuapp.com/"
    REDIRECT_URI = "http://glacial-fjord-8454.herokuapp.com/Oauth"
    JAVASCRIPT_ORIGINS = "http://glacial-fjord-8454.herokuapp.com/"
  end

  before do
    logger.info "Request Headers: #{headers}"
    logger.warn "Params: #{params}"
  end

  after do
    logger.info "Response Headers: #{response.headers}"
  end

  # TweetStream.configure do |config|
  #   config.consumer_key       = 'jT0oo2sWwxcATUpYHxm6oNbXA'
  #   config.consumer_secret    = 'yY1xTQy73tQMvZsOQmGmRl4cx5amq8yrpB6ru5AuhD9AhgL45D'
  #   config.oauth_token        = '95246661-SOQsy4oZM6HgogQVCUwkeQ2UcvxFqhzrRbvrLm88H'
  #   config.oauth_token_secret = 'jutb4vmi3HwBGujNGzjmgIfQHg7eqP9Vr1UacUxLbmf3O'
  #   config.auth_method        = :oauth
  # end

  ########################
  # Keys and ID's
  ########################

  Geo_API_Key = "5652d2f22aa2c9ef461c5bb22ce1fa20:0:69767276"
  Weather_API_Key = "11fb2f7f63a41afe"

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

  #TWITTER CREDENTIALS
  c_key = 'jT0oo2sWwxcATUpYHxm6oNbXA'
  c_secret = 'yY1xTQy73tQMvZsOQmGmRl4cx5amq8yrpB6ru5AuhD9AhgL45D'
  c_key_secret = "#{c_key}:#{c_secret}"
  encoded_c_key_secret = Base64.strict_encode64(c_key_secret)


  ########################
  # DB Configuration
  ########################

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

  ########################
  # Routes
  ########################

  get('/') do
#     gapi.auth.signIn(
#  parameters
# )

    state = SecureRandom.urlsafe_base64
    @google_post = "https://accounts.google.com/o/oauth2/auth?scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fplus.login&state=#{state}&redirect_uri=#{REDIRECT_URIS_GOOGLE}&response_type=code&client_id=#{CLIENT_ID_GOOGLE}&access_type=offline"
    render(:erb, :index, :layout => :layout)
    # redirect to('/profile')
  end

  get('/oauth2callback') do
    code = params["code"]
    response = HTTParty.post("https://accounts.google.com/o/oauth2/token",
      :body => {:code => code,
                :client_id => CLIENT_ID_GOOGLE,
                :client_secret => CLIENT_SECRET_GOOGLE,
                :redirect_uri => REDIRECT_URIS_GOOGLE,
                :grant_type => "authorization_code"
      })

    session[:access_token_google] = response["access_token"]
    redirect to("/profile")
    end


  get('/feed/:id') do
    $current_feed_id = "user:#{@id}"
    # @feed = $redis.keys.sort_by {|s| s[/\d+/].to_i}[params[:id].to_i]
    @feed_hash = $redis.get($current_feed_id)
    redirect to("/snapshot/show")
  end

  get('/snapshot/show') do

    # binding.pry
    @edit = "true" if params[:edit] == "true"
    @edit = "false" if params[:edit] == "false" || @edit == nil
    # binding.pry
    if params[:index] == $current_feed_id
      @edit = "true"
      # @feed = $redis.keys.sort_by {|s| s[/\d+/].to_i}[params[:index].to_i + 1]
      @feed_hash = JSON.parse($redis.get($current_feed_id))
    elsif params[:index]
      # @edit = "false"
      $current_feed_id = "user:#{params[:index].to_i + 1}"
      @feed_hash = JSON.parse($redis.get($current_feed_id))
    else
      $current_feed_id = $redis.keys.sort_by {|s| s[/\d+/].to_i}.last
    end
    @feed_hash = JSON.parse($redis.get($current_feed_id))
    @id = @feed_hash["id"]
    @concept_name = @feed_hash["concept_name"]
    @latitude = @feed_hash["latitude"]
    @longitude = @feed_hash["longitude"]
    @icon_url = @feed_hash["icon_url"]
    @icon = @feed_hash["icon"]
    @feels_like = @feed_hash["feels_like"]
    @temp = @feed_hash["temp"]
    @instagram_urls = @feed_hash["instagram"]
    @trending_results = @feed_hash["trending_results"]
    @statuses = @feed_hash["statuses"]
    # binding.pry

    # Use 'track' to track a list of single-word keywords
# TweetStream::Client.new.track('term1') do |status|
#   puts "#{status.text}"
# end



# TweetStream::Client.new.locations((@latitude.to_i + 0.1),(@longitude.to_i + 0.1),(@latitude.to_i - 0.1),(@longitude.to_i - 0.1 )) do |tweet|
#   binding.pry
# end




# binding.pry
# TweetStream::Client.new.sample do |status|
#   # The status object is a special Hash with
#   # method access to its keys.
#   binding.pry
#   puts "#{status.text}"
# end
# stream = Tweetstream.new(options[:tag], options[:from])
# output = stream.render(options[:template])
    render(:erb, :_snapshot, :layout => :layout)
  end


  get('/snapshot') do
    # binding.pry
    #retrieve geolocation
    nytimes_url = "http://api.nytimes.com/svc/semantic/v2/geocodes/query.json?&name=#{params[:keyword].gsub(' ', '+')}&perpage=1&api-key=#{Geo_API_Key}"
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
    response = Twitters.post('/oauth2/token', :body => body, :headers => headers)
    bearer_token = response['access_token']
    headers = 
    {
      'Authorization' => "Bearer #{bearer_token}", 
      'Content-Type'  => "application/x-www-form-urlencoded;charset=UTF-8"
    }
    #twitter get and manipulate data    
    get_woeid_url = "https://api.twitter.com/1.1/trends/closest.json?lat=#{@latitude}&long=#{@longitude}"
    woeid_results = Twitters.get(get_woeid_url, :headers => headers)
    woeid = woeid_results.to_a[0]["woeid"]
    trending_query = "https://api.twitter.com/1.1/trends/place.json?id=#{woeid}"
    @trending_results = Twitters.get(trending_query , :headers => headers)[0]["trends"]
    #Instagram
    client = Instagram.client(:access_token => session[:access_token])
    results = client.media_search(@latitude,@longitude)
    @instagram_urls = []
    results.each do |result|
      @instagram_urls.push(result["images"]["low_resolution"]["url"])
    end

    #Twitter stream
    # statuses = []
    # TweetStream::Client.new.track("#{params[:keyword].gsub(' ','')}") do |status, client|
    #   statuses << status
    #   client.stop if statuses.size >= 5
    # end

    # @statuses = statuses.map do |status|
    #   {user_name: status.user.name, text: status.full_text}
    # end

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
      "trending_results" => @trending_results,
      "statuses" => @statuses
    }
    Feed.new(feed_hash)
    redirect to('/snapshot/show')
  end


  get('/profile') do
    @feeds = $redis.keys.sort_by {|s| s[/\d+/].to_i}
    render(:erb, :profile, :layout => :layout)
  end


  delete('/profile/instagram/:id') do
    # current = JSON.parse($redis.get($redis.keys.sort[-2]))
    
    current_feed = JSON.parse($redis.get($current_feed_id))
    current_feed["instagram"].delete_at(params[:id].to_i)
    $redis.set("user:#{current_feed["id"]}", current_feed.to_json)
    redirect to ("/snapshot/show?index=#{$current_feed_id}")
  end

  delete('/profile/feed/:id') do
    # current = JSON.parse($redis.get($redis.keys.sort[-2]))
    
    current_feed = JSON.parse($redis.get($current_feed_id))
    current_feed["instagram"].delete_at(params[:id].to_i)
    $redis.set("user:#{current_feed["id"]}", current_feed.to_json)
    redirect to ("/snapshot/show?index=#{$current_feed_id}")
  end

end


