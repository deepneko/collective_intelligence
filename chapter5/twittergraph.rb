require 'rubygems'
gem 'twitter4r', '>=0.3.0'
require 'twitter'
require 'twitter/console'
require 'sqlite3'
require 'hpricot'
require 'mechanize'
require 'kconv'

class TwitterGraph
  def initialize(friends)
    @myuser = "deepneko"
    @friendlist = friends
    @namelist = []
    @friendlist.each do |f|
      @namelist << f.screen_name
    end
    @con = SQLite3::Database.new("twitter.db")
    @agent = login
  end

  def login
    agent = WWW::Mechanize.new
    agent.max_history = 1
    agent.user_agent_alias = 'Windows IE 6'
    login_page = agent.get('http://twitter.com/')
    login_form = login_page.forms[1]
    login_form['session[username_or_email]'] = "deepneko"
    login_form['session[password]'] = "shin2812"
    my_home = agent.submit(login_form)
    agent
  end

  def createdb
    sql = "create table friendsmatrix (screen_name,";
    @namelist.each do |name|
      sql += name + ","
    end
    sql = sql.slice(0, sql.size-1) + ")"
    @con.execute(sql)
  end

  def insertdb
    @namelist.each do |name|
      count = 1
      f_loop = 1
      sql = "insert into friendsmatrix (screen_name,";
      insert_count = 0

      p name

      while f_loop
        friends_page = @agent.get("http://twitter.com/#{name}/friends?page=#{count}")
        doc = Hpricot(friends_page.body)

        (doc/"strong"/:a).each do |text|
          if @namelist.index(text.innerText)
            sql += text.innerText + ","
            insert_count += 1
          end
        end

        # Next or Previous
        if (doc/"div.pagination"/:a).size == 1
          (doc/"div.pagination"/:a).each do |link|
            if /Next/ =~ link.innerText
              count += 1
            else
              f_loop = nil
            end
          end
        # Next and Previous
        elsif (doc/"div.pagination"/:a).size == 2
          count += 1
        else
          f_loop = nil
        end
      end

      if insert_count != 0
        sql = sql.slice(0, sql.size-1) + ") values ('#{name}',"
        for i in 0...insert_count
          sql += "1,"
        end
        sql = sql.slice(0, sql.size-1) + ")"

        p sql
        @con.execute(sql)
      end
    end
  end
end

twitter = Twitter::Client.new(
                              "login" => "deepneko",
                              "password" => "shin2812"
                              )
friends = twitter.my(:friends)

twittergraph = TwitterGraph.new(friends)
#twittergraph.createdb
twittergraph.insertdb

