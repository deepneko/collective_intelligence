require 'rubygems'
require 'sqlite3'
require 'const'
require 'searcher.rb'

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
      if words.size == 0
        return
      end
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
      else
        return
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
    
    weights = [[1.0, frequencyscore(rows)],
               [1.0, locationscore(rows)],
               [1.0, pagerankscore(rows)]]

    weights.each { |pair|
      weight = pair.shift
      scores = pair.shift
      totalscores.each_key { |url|
        totalscores[url] += weight * scores[url]
      }
    }

    return totalscores
  end

  def geturlname(id)
    cur = @con.execute("select url from urllist where rowid='#{id}'")
    return cur[0][0]
  end

  def query(q)
    rows = wordids = getmatchrows(q)
    if !rows
      return ""
    end
    scores = getscoredlist(rows, wordids)
    scores_a = scores.to_a.sort{|a, b|
      (b[1] <=> a[1]) * 2 + (a[0] <=> b[0])
    }

    html = ""
    scores_a.each { |s|
      #print s[1].to_s + "<br>"
      url = geturlname(s[0])
      html += "<a href='" + url + "'>" + url + "</a><br>"
    }
    return html
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

  def locationscore(rows)
    locations = Hash.new
    rows.each { |row|
      locations[row[0]] = 1000000
    }

    rows.each { |row|
      loc = 0
      row.slice(1, row.size).each { |l|
        loc += l.to_i
      }
      if loc < locations[row[0]]
        locations[row[0]] = loc
      end
    }

    return normalizescores(locations, smallIsBetter=1)
  end

  def distancescore(rows)
    mindistance = Hash.new
    if rows.size <= 2
      rows.each { |row|
        mindistance[row[0]] = 1.0
      }
      return mindistance
    end

    rows.each { |row|
      mindistance[row[0]] = 1000000
    }

    rows.each { |row|
      dist = 0.0
      for i in 2...row.size
        dist += (row[i].to_f - row[i-1].to_f).abs
      end
      if dist < mindistance[row[0]]
        mindistance[row[0]] = dist
      end
    }
    
    return normalizescores(mindistance, smallIsBetter=1)
  end

  def pagerankscore(rows)
    pageranks = Hash.new
    rows.each { |row|
      pageranks[row[0]] = @con.execute("select score from pagerank where urlid=#{row[0]}")[0][0]
    }
    maxrank = pageranks.values.max.to_f

    normalizedscores = Hash.new
    pageranks.each_pair { |u, l|
      normalizedscores[u] = l.to_f / maxrank
    }

    return normalizedscores
  end
end

#const = Const.new
#searcher = Searcher.new(const.dbname)
#searcher.query(ARGV[0])
