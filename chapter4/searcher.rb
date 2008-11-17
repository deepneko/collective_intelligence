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
    words = q.split(/\s/)
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
end

const = Const.new
searcher = Searcher.new(const.dbname)
p searcher.getmatchrows(ARGV[0])
