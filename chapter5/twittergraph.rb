require 'rubygems'
gem 'twitter4r', '>=0.3.0'
require 'twitter'
require 'twitter/console'
require 'sqlite3'
require 'curl'

class TwitterGraph
  def initialize(friends)
    @friendlist = friends
    @con = SQLite3::Database.new("twitter.db")
  end

  def createdb
    first = @friendlist.shift.screen_name
    sql = "create table friendsmatrix (" + first;
    @friendlist.each do |f|
      sql += "," + f.screen_name
    end
    sql += ")"
    @friendlist.unshift(first)
    @con.execute(sql)
  end

  def initdb
    @friendlist.each do |f|
      
    end
  end

  def isfriend(user_a, user_b)
#    curl = Curl::Easy.perform("http://twitter.com/friendships/exsists.json?user_a=#{user_a}&user_b=#{user_b}")
    curl = Curl::Easy.perform("http://twitter.com/")
    p curl.body_str
  end
end

twitter = Twitter::Client.new(
                              "login" => "deepneko",
                              "password" => "shin2812"
                              )

friends = twitter.my(:friends)
#p friends.size

#friends.each do |friend|
#  p friend.screen_name
#end

twittergraph = TwitterGraph.new(friends)
#twittergraph.createdb
twittergraph.isfriend("ryo_katsuma", "gakkie")
