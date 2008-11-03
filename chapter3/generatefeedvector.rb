#!/usr/bin/env ruby -Ku

require 'open-uri'
require 'rss'
require 'MeCab'
require 'uri'

# generate word list and blog list
class GenerateFeedVector
  def initialize
    @out = "blogdata.txt"
    @bloglist = []
    @wordcounts = Hash.new
  end

  def init(file)
    f = open(file, "r")
    begin
      f.each_line do |line|
        rss = ""
        content = ""

        array = line.split(",")
        blog = Blog.new(array[0], array[1])

        open(array[1]){|f|
          content = f.read
        }

        mecab = MeCab::Tagger.new("-Ochasen")
        begin
          rss = RSS::Parser::parse(content)
        rescue RSS::InvalidRSSError
          puts "#warning:" + blog.blogger + "'s rss is invalid"
          next
        end

        @bloglist << blog

        # parse rss description for each blog
        begin
          rss.items.each do |item|

            # parse rss description
            node = mecab.parseToNode(rm_html_tag(delete_uri(item.description)))
            while node.next
              node = node.next
              word = node.surface

              # add word and increment wordcounts
              if @wordcounts[word]
                if !blog.hasWord(word)
                  blog.addWord(word)
                  @wordcounts[word] += 1
                end
              else
                blog.addWord(word)
                @wordcounts[word] = 1
              end
            end
          end

          # debug
          p blog.blogger

        rescue
          puts "#warning:" + blog.blogger + "'s rss is invalid"
          next
        end
      end
    ensure
      f.close
    end

    #debug
    #p @bloglist
    #p @wordcounts

    # threshold for word count
    @wordcounts.each_pair{|word, count|
      frac = count.to_f / @bloglist.length.to_f
      if frac < 0.2 || frac > 0.5
        @wordcounts.delete(word)
      end
    }

    # create blog - word matrix
    # row blog
    # col word
    f = open(@out, "w");
    begin
      @wordcounts.each_key{|w|
        f.write("\t" + w)
      }
      f.write("\n")

      @bloglist.each{|b|
        f.write(b.blogger)
        @wordcounts.each_pair {|word, count|
          if b.hasWord(word)
            f.write("\t" + count.to_s)
          else
            f.write("\t0")
          end
        }
        f.write("\n")
      }
    ensure
      f.close
    end
  end

  # delete html tags
  def rm_html_tag(str)
    str.sub!(/<[^<>]*>/,"") while /<[^<>]*>/ =~ str
    str
  end

  # delete url
  def delete_uri(s)
    str = s.dup
    URI.extract(s, %w[http https ftp]) do |uri|
      str.gsub!(uri, "")
    end
    str
  end
end

# blog param
class Blog
  def initialize(blogger, feed)
    @blogger = blogger
    @feed = feed
    @wordlist = Hash.new
  end

  def addWord(w)
    @wordlist[w] = 1
  end

  def hasWord(w)
    @wordlist[w]
  end

  def blogger
    @blogger
  end

  def feed
    @feed
  end
end

require 'const.rb'
const = Const.new

gfv = GenerateFeedVector.new
if ARGV[0]
  gfv.init(ARGV[0])
else
  gfv.init(const.rsslist)
end
