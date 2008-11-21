require 'rubygems'
require 'sqlite3'
require 'const'

class Searcher
  def initialize(dbname)
    __init__(dbname)
  end

  def __init__(dbname)
    @con = SQLite3::Database.new(dbname)
  end

  def __del__
    @con.close
  end

  def getmatchrows(q)
    fieldlist = "w0.urlid"
    tablelist = ""
    clauselist = ""
    wordids = []
    
    #separate words with space
    if q
      words = q.split(/\s/)
    else
      return
    end
    tablenumber = 0

    words.each { |word|
      wordrow = @con.execute("select rowid from wordlist where word='#{word}'")
      if wordrow.size != 0
        wordid = wordrow[0]
        wordids << wordid
        if tablenumber > 0
          tablelist += ","
          clauselist += " and "
          clauselist += "w#{tablenumber-1}.urlid=w#{tablenumber}.urlid and "
        end
        fieldlist += ",w#{tablenumber}.location"
        tablelist += "wordlocation w#{tablenumber}"
        clauselist += "w#{tablenumber}.wordid='#{wordid}'"
        tablenumber += 1
      end
    }

    fullquery = "select #{fieldlist} from #{tablelist} where #{clauselist}"
    cur = @con.execute(fullquery)

    return cur
  end

  def getscoredlist(rows, wordids)
    totalscores = Hash.new
    rows.each { |row|
      totalscores[row[0]] = 0.0
    }
    
    #TODO すべて1.0の重みづけがしてあるが・・・？
    weights = frequencyscore(rows)

    totalscores.each_key { |url|
      totalscores[url] += weights[url]
    }

    return totalscores
  end

  def geturlname(id)
    cur = @con.execute("select url from urllist where rowid='#{id}'")
    return cur[0]
  end

  def query(q)
    rows = wordids = getmatchrows(q)
    scores = getscoredlist(rows, wordids)
    scores.to_a.sort{|a, b|
      (b[1] <=> a[1]) * 2 + (a[0] <=> b[0])
    }
    
    scores.each { |s|
      print s[1].to_s + " "
      p geturlname(s[0])
    }
  end

  def normalizescores(scores, smallIsBetter=0)
    vsmall = 0.00001
    nscores = Hash.new
    if smallIsBetter == 1
      minscore = scores.values.min
      scores.each_pair { |u, l|
        t = [vsmall, l]
        nscores[u] = minscore.to_f / t.max
      }
    else
      maxscore = scores.values.max
      if maxscore == 0
        maxscore = vsmall
      end
      scores.each_pair { |u, c|
        nscores[u] = c.to_f / maxscore
      }
    end
    return nscores
  end

  def frequencyscore(rows)
    counts = Hash.new
    rows.each { |row|
      counts[row[0]] = 0
    }
    rows.each { |row|
      counts[row[0]] += 1
    }
    return normalizescores(counts)
  end
end

const = Const.new
searcher = Searcher.new(const.dbname)
#p searcher.getmatchrows(ARGV[0])
searcher.query(ARGV[0])
