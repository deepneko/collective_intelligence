require 'rubygems'
require 'sqlite3'

class Searchnet
  def initialize(dbname)
    __init__(dbname)
  end

  def __init__(dbname)
    @con = SQLite3::Database.new(dbname)
  end

  def __del__
    @con.close
  end

  def droptables
    @con.execute("drop table hiddennode");
    @con.execute("drop table wordhidden");
    @con.execute("drop table hiddenurl");
  end

  def maketables
    @con.execute("create table hiddennode(create_key)")
    @con.execute("create table wordhidden(fromid, toid, strength)")
    @con.execute("create table hiddenurl(fromid, toid, strength)")
  end

  def getstrength(fromid, toid, layer)
    if layer == 0
      table = 'wordhidden'
    else
      table = 'hiddenurl'
    end

    res = @con.execute("select strength from #{table} where fromid='#{fromid}' and toid='#{toid}'")
    if res.size == 0
      if layer == 0
        return -0.2
      elsif layer == 1
        return 0
      end
    end

    return res[0][0].to_f
  end

  def setstrength(fromid, toid, leyer, strength)
    if leyer == 0
      table = 'wordhidden'
    else
      table = 'hiddenurl'
    end

    res = @con.execute("select rowid from #{table} where fromid='#{fromid}' and toid='#{toid}'")
    if res.size == 0
      @con.execute("insert into #{table} (fromid, toid, strength) values ('#{fromid}', '#{toid}', '#{strength}')")
    else
      rowid = res[0]
      @con.execute("update #{table} set strength='#{strength}' where rowid='#{rowid}'")
    end
  end

  def generatehiddennode(wordids, urls)
    if wordids.size > 3
      return nil
    end

    createkey = ""
    wordids.each { |wi|
      createkey += "_" + wi.to_s
    }

    res = @con.execute("select rowid from hiddennode where create_key='#{createkey}'")
    if res.size == 0
      cur = @con.execute("insert into hiddennode (create_key) values ('#{createkey}')")
      hiddenid = getlastrowid("hiddennode")
      wordids.each { |wordid|
        setstrength(wordid, hiddenid, 0, 1.0/wordids.size)
      }
      urls.each { |urlid|
        setstrength(hiddenid, urlid, 1, 0.1)
      }
    end
  end

  def getallhiddenids(wordids, urlids)
    l1 = Hash.new
    wordids.each { |wordid|
      cur = @con.execute("select toid from wordhidden where fromid='#{wordid}'")
      cur.each { |row|
        l1[row[0]] = 1
      }
    }
    urlids.each { |urlid|
      cur = @con.execute("select fromid from hiddenurl where toid='#{urlid}'")
      cur.each { |row|
        l1[row[0]] = 1
      }
    }
    return l1.keys
  end

  def setupnetwork(wordids, urlids)
    @wordids = wordids
    @hiddenids = getallhiddenids(wordids, urlids)
    @urlids = urlids

    @ai = Array.new(@wordids.size){1.0}
    @ah = Array.new(@hiddenids.size){1.0}
    @ao = Array.new(@urlids.size){1.0}

    @wi = []
    @wo = []
    @wordids.each { |wordid|
      wi_elem = []
      @hiddenids.each { |hiddenid|
        wi_elem << getstrength(wordid, hiddenid, 0)
      }
      @wi << wi_elem
    }
    @hiddenids.each { |hiddenid|
      wo_elem = []
      @urlids.each { |urlid|
        wo_elem << getstrength(hiddenid, urlid, 1)
      }
      @wo << wo_elem
    }
  end

  def feedforward
    for i in 0...@wordids.size
      @ai[i] = 1.0
    end

    for j in 0...@hiddenids.size
      sum = 0.0
      for i in 0...@wordids.size
        sum = sum + @ai[i] * @wi[i][j]
      end
      @ah[j] = Math.tanh(sum)
    end

    for k in 0...@urlids.size
      sum = 0.0
      for j in 0...@hiddenids.size
        sum = sum + @ah[j] * @wo[j][k]
      end
      @ao[k] = Math.tanh(sum)
    end

    @ao
  end

  def getresult(wordids, urlids)
    setupnetwork(wordids, urlids)
    return feedforward
  end

  def backPropagate(targets, n=0.5)
    output_deltas = Array.new(@urlids.size){0.0}
    for k in 0...@urlids.size
      error = targets[k] - @ao[k]
      output_deltas[k] = dtanh(@ao[k]) * error
    end

    hidden_deltas = Array.new(@hiddenids.size){0.0}
    for j in 0...@hiddenids.size
      error = 0.0
      for k in 0...@urlids.size
        error = error + output_deltas[k] * @wo[j][k]
      end
      hidden_deltas[j] = dtanh(@ah[j]) * error
    end

    for j in 0...@hiddenids.size
      for k in 0...@urlids.size
        change = output_deltas[k] * @ah[j]
        @wo[j][k] += n*change
      end
    end

    for i in 0...@wordids.size
      for j in 0...@hiddenids.size
        change = hidden_deltas[j] * @ai[i]
      end
    end
    @wi[i][j] += n*change
  end

  def trainquery(wordids, urlids, selectedurl)
    generatehiddennode(wordids, urlids)
    setupnetwork(wordids, urlids)
    feedforward
    targets = Array.new(urlids.size){0.0}
    targets[urlids.index(selectedurl)] = 1.0
    error = backPropagate(targets)
    updatedatabase
  end

  def updatedatabase
    for i in 0...@wordids.size
      for j in 0...@hiddenids.size
        setstrength(@wordids[i], @hiddenids[j], 0, @wi[i][j])
      end
    end

    for j in 0...@hiddenids.size
      for k in 0...@urlids.size
        setstrength(@hiddenids[j], @urlids[k], 1, @wo[j][k])
      end
    end
  end

  def getlastrowid(table)
        cur = @con.execute("select rowid from #{table} order by rowid desc limit 1")
    return cur[0][0]
  end

  def dtanh(y)
    return 1.0-y*y
  end
end

#mynet = Searchnet.new("nn.db")
#mynet.droptables()
#mynet.maketables()
#wWorld = 101
#wRiver = 102
#wBank = 103
#uWorldBank = 201
#uRiver = 202
#uEarth = 203
#mynet.generatehiddennode([wWorld,wBank], [uWorldBank,uRiver,uEarth])
#allurls = [uWorldBank, uRiver, uEarth]
#for i in 0...30
#  mynet.trainquery([wWorld,wBank], allurls, uWorldBank)
#  mynet.trainquery([wRiver,wBank], allurls, uRiver)
#  mynet.trainquery([wWorld], allurls, uEarth)
#end
#p mynet.getresult([wWorld,wBank], allurls)
#p mynet.getresult([wRiver,wBank], allurls)
#p mynet.getresult([wBank], allurls)
