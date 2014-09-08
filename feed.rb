class Feed
	def initialize(feed_form)
		@city = feed_form[:city]
		@state = feed_form[:state]
		user = {
			city: feed_form[:city],
			state: feed_form[:state]
		}

		index = $redis.incr("user:index")
  		user[:id] = index
  # keys.count and each_with_index won't work properly because there's no guarantee of order with a hash
  		$redis.set("user:#{index}", user.to_json)
	end
end