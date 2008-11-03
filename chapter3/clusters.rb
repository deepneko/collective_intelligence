#!/usr/bin/env ruby -Ku

class Clusters
  def initialize
    @colnames = []
    @rownames = []
    @data = []
  end

  def readfile(file)
    f = open(file, "r")
    count = 0
    begin
      f.each_line do |line|
        if count == 0
          @colnames = line.split(/\s*\t\s*/)
          count += 1
        else
          p = line.split(/\s*\t\s*/)
          @rownames << p.shift

          datatemp = []
          p.each{|x| datatemp << x.to_i}
          @data << datatemp
        end
      end
    ensure
      f.close
    end
  end

  # hierarchical clustering
  def hcluster(&block)
    distances = Hash.new
    distancepair = []
    clust = []
    currentclustid = -1

    # initialized clusters are rows
    for i in 0...@data.size
      clust << BiCluster.new(@data[i], i)
    end

    while clust.size > 1
      p "cluster size:" + clust.size.to_s
      p "current cluster id:" + currentclustid.to_s

      lowestpair = [0, 1]
      closest = block.call(clust[0].vec, clust[1].vec)

      # find nearest cluster
      for i in 0...clust.size 
        for j in i+1...clust.size
          distancepair = []
          distancepair << clust[i].id << clust[j].id

          if !distances.key? (distancepair)
            distances[distancepair] = block.call(clust[i].vec, clust[j].vec)
          end

          d = distances[distancepair]
#          if d == 0 && clust[i].id >= 0 && clust[j].id >= 0
#            p @rownames[clust[i].id]
#            p @rownames[clust[j].id]
#            p "   "
#          end
          if d < closest
            closest = d
            lowestpair.clear
            lowestpair << i << j
          end
        end
      end

      # calculate distance for two clusters
      mergevec = []
      for i in 0...clust[0].vec.size
        mergevec << (clust[lowestpair[0]].vec[i] + clust[lowestpair[1]].vec[i]) / 2.0
      end

      newcluster = BiCluster.new(mergevec, currentclustid,
                                 left=clust[lowestpair[0]], right=clust[lowestpair[1]],
                                 distance=closest)

      #p currentclustid.to_s + ":" + clust[lowestpair[0]].id.to_s + ":" + clust[lowestpair[1]].id.to_s

      currentclustid -= 1
      clust.delete_at(lowestpair[1])
      clust.delete_at(lowestpair[0])
      clust << newcluster
    end

    return clust[0]
  end

  # k-means
  def kcluster(k=4, num=100, &block)
    ranges = []

    for i in 0...@data[0].size
      range = []
      minmax = []
      @data.each {|v|
        range << v[i]
      }
      ranges << (minmax << range.min << range.max)
    end

    # set random clusters * k
    clusters = []
    for i in 0...k
      cluster = []
      ranges.each {|v|
        cluster << rand * (v[1] - v[0]) + v[0]
      }
      clusters << cluster
    end

    # main loop * num iterations
    lastmatches = []
    for n in 0...num
      p "Iteration:" + n.to_s

      bestmatches = []
      for i in 0...k
        bestmatches << []
      end

      # add each data to nearest cluster
      for j in 0...@data.size
        row = @data[j]
        bestmatch = 0
        for i in 0...clusters.size
          d = block.call(clusters[i], row)
          if d < block.call(clusters[bestmatch], row)
            bestmatch = i
          end
        end
        bestmatches[bestmatch] << j
      end

      # if bestmatches didn't change, then break
      if bestmatches == lastmatches
        break
      end
      lastmatches = bestmatches

      # calculate center of current clusters
      for i in 0...k
        avgs = []
        for j in 0...@data[0].size
          avgs << 0.0
        end

        if bestmatches[i].size > 0
          bestmatches[i].each{|rowid|
            for m in 0...@data[rowid].size
              avgs[m] += @data[rowid][m]
            end
          }

          for j in 0...avgs.size
            avgs[j] /= bestmatches[i].size
          end

          clusters[i] = avgs
        end
      end
    end

    return bestmatches
  end

  def print_hclust(clust, labels=@rownames, n=0)
    for i in 0...n
      print "  "
    end

    if clust.id < 0
      p "-"
    else
      p labels[clust.id]
    end

    if clust.left
      print_hclust(clust.left, labels, n=n+1)
    end

    if clust.right
      print_hclust(clust.right, labels, n=n+1)
    end
  end

  def print_kclust(clust)
    clust.each{|c|
      c.each{|x|
        print "  " + @rownames[x] + "\n"
      }
      print "\n"
    }
  end

  def rownames
    @rownames
  end

  def colnames
    @colnames
  end
end

class BiCluster
  def initialize(vec, id, left=nil, right=nil, distance=nil)
    @vec = vec
    @id = id

    @left = left
    @right = right
    @distance = distance
  end

  def id
    @id
  end

  def vec
    @vec
  end

  def left
    @left
  end

  def right
    @right
  end

  def distance
    @distance
  end
end

require "const.rb"
require "visualizer.rb"

const = Const.new
distance = const.pearson

clusters = Clusters.new
if ARGV[0]
  clusters.readfile(ARGV[0])
else
  clusters.readfile(const.matrixdata)
end

hclust = clusters.hcluster(&distance)
clusters.print_hclust(hclust)

visualizer = Visualizer.new
visualizer.drawdendrogram(hclust, clusters.rownames, const.dendrogram)

#kclust = clusters.kcluster(&distance)
#clusters.print_kclust(kclust)
