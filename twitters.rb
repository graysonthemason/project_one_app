class Twitters
  include HTTParty
  base_uri  'https://api.twitter.com'
  format    :json
end