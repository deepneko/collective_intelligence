require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'sqlite3'
require 'const'

class Crawler
  def initialize(dbname)
    @const = Const.new
    @ignorewords = ['the', 'of', 'to', 'and', 'a', 'in', 'is', 'it']
    __init__(dbname)
  end

  def __init__(dbname)
    @con = SQLite3::Database.new(dbname)
  end

  def __del__
    @con.close
  end

  def dbcommit
    @con.commit
  end

  def droptables
    @con.execute('drop table urllist')
    @con.execute('drop table wordlist')
    @con.execute('drop table wordlocation')
    @con.execute('drop table link')
    @con.execute('drop table linkwords')
  end

  def createindextables
    @con.execute('create table urllist(url)')
    @con.execute('create table wordlist(word)')
    @con.execute('create table wordlocation(urlid, wordid, location)')
    @con.execute('create table link(fromid integer, toid integer)')
    @con.execute('create table linkwords(wordid, linkid)')
    @con.execute('create index wordidx on wordlist(word)')
    @con.execute('create index urlidx on urllist(url)')
    @con.execute('create index wordurlidx on wordlocation(wordid)')
    @con.execute('create index urltoidx on link(toid)')
    @con.execute('create index urlfromidx on link(fromid)')
  end

  def getentryid(table, field, value, createnew=true)
    cur = @con.execute("select rowid from #{table} where #{field}='#{value}'")
    if cur.size == 0
      @con.execute("insert into #{table}(#{field}) values('#{value}')")
      return getlastrowid(table)
    else
      return cur[0][0]
    end
  end

  def addtoindex(url, hpricot)
    if isindexed(url)
      return
    end
    print "Indexing " + url + "\n"

    #get each word
    text = gettextonly(hpricot)
    words = separatewords(text)

    #get url id
    urlid = getentryid('urllist', 'url', url)

    #each word link this url or not
    for i in 0...words.size
      word = words[i]
      if @ignorewords.index(word)
        next
      end

      wordid = getentryid('wordlist', 'word', word)
      @con.execute("insert into wordlocation(urlid, wordid, location) \
                   values ('#{urlid}', '#{wordid}', '#{i}')")
    end
  end

  #TODO delete tag for each_child element?
  def gettextonly(hpricot)
    v = hpricot.to_s
    if v != nil
      return hpricot.inner_text()
    else
      return v.strip
    end
  end

  def separatewords(text)
    words = []
    text.split(/\W+/).each { |s|
      words << s.downcase
    }
    return words
  end

  def isindexed(url)
    u = @con.execute("select rowid from urllist where url='#{url}'")
    if u.size != 0
      v = @con.execute("select * from wordlocation where urlid='#{u[0]}'")
      if v.size != 0
        return true
      end
    end
    return false
  end

  def getlastrowid(table)
    cur = @con.execute("select rowid from #{table} order by rowid desc limit 1")
    return cur[0][0]
  end

  def addlinkref(urlFrom, urlTo, linkText)
    words = separatewords(linkText)
    fromid = getentryid('urllist', 'url', urlFrom)
    toid = getentryid('urllist', 'url', urlTo)
    if fromid == toid
      return
    end
    @con.execute("insert into link(fromid, toid) values('#{fromid}', '#{toid}')")
    linkid = getlastrowid("link")
    words.each { |word|
      if @ignorewords.index(word)
        next
      end

      wordid = getentryid('wordlist', 'word', word)
      @con.execute("insert into linkwords(linkid, wordid) values('#{linkid}', '#{wordid}')")
    }
  end

  def urljoin(base, url)
    if base.index("http://") == 0
      bases = base.split(/\s*\/\s*/)
      return  "http://" + bases[2] +  url
    end

    return base + url
  end

  def crawl(pages, depth=2)
    for i in 0...depth
      newpages = []
      pages.each { |page|
        begin
          c = open(page)
        rescue
          print "Could not open " + page + "\n"
          next
        end

        # scraping url with hpricot
        doc = Hpricot(c.read)
        addtoindex(page, doc)

        (doc/:a).each { |link|
          if link[:href]
            url = urljoin(page, link[:href])
            if url.index("'")
              next
            end

            url = url.split(/\s*\#\s*/)[0]
            if !isindexed(url)
              p "add indexed:" + url
              newpages << url
            end

            linkText = gettextonly(link)
            addlinkref(page, url, linkText)
          end
        }
      }
      pages = newpages
    end
  end

  def inboundlinkscore(rows)
    uniqueurls = []
    rows.each { |row|
      uniqueurls << row[0]
    }

    inboundcount = Hash.new
    uniqueurls.each { |u|
      inboundcount[u] = @con.execute("select count(*) from link where toid='#{u}")[0]
    }

    return normalizescores(inboundcount)
  end

  def calculatepagerank(iterations=20)
    @con.execute("drop table if exists pagerank")
    @con.execute("create table pagerank(urlid primary key, score)")
    @con.execute("insert into pagerank select rowid, 1.0 from urllist")

    for i in 0...iterations
      print "Iteration #{i}\n"
      rowids = @con.execute("select rowid from urllist")
      rowids.each { |urlid|
        pr = 0.15
        linkers = @con.execute("select distinct fromid from link where toid='#{urlid}'").flatten
        linkers.each { |linker|
          linkingpr = @con.execute("select score from pagerank where urlid=#{linker}")[0][0]
          linkingcount = @con.execute("select count(*) from link where fromid='#{linker}'")[0][0]
          pr += 0.85 * (linkingpr.to_f / linkingcount.to_i)
        }
        @con.execute("update pagerank set score='#{pr}' where urlid=#{urlid}")
      }
    end
  end
end

const = Const.new

crawler = Crawler.new(const.dbname)

#crawler.droptables
#crawler.createindextables
#pages = ['http://kiwitobes.com/wiki/Categorical_list_of_programming_languages.html']
#crawler.crawl(pages)

crawler.calculatepagerank
