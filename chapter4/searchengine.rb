require 'rubygems'
require 'hpricot'
require 'open-uri'

doc = Hpricot( open(ARGV[0]).read )

(doc/:a).each do |link|
  puts "#{link.inner_html}->#{link[:href]}"
end

class Crawler
  def initialize(self, dbname)
  end

  def dbcommit(self)
  end

  def getentryid(self, table, field, value, createnew=true)
  end

  def addtoindex(self, url, hpricot)
    print "Indexin " + url
  end

  def gettextonly(self, hpricot)
  end

  def separetewords(self, text)
    return nil
  end

  def isindexed(self, url)
    return false
  end

  def addlinkref(self, urlFrom, urlTo, linkText)
  end

  def crawl(self, pages, depth=2)
  end

  def createindextables(self)
  end
end
