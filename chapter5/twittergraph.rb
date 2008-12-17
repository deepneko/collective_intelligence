require 'rubygems'
gem 'twitter4r', '>=0.3.0'
require 'twitter'
require 'twitter/console'

twitter = Twitter::Client.new(
                              "login" => "deepneko",
                              "password" => "shin2812"
                              )

friends = twitter.my(:friends)
p friends.size

friends.each do |friend|
  p friend.screen_name
end






