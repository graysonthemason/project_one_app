class Twitter
  include HTTParty
  base_uri  'https://api.twitter.com'
  format    :json
end
	