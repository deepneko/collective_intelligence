class Const
  attr_accessor :rsslist
  attr_accessor :matrixdata
  attr_accessor :distance

  def initialize
    @rsslist = "rsslist.csv"
    @matrixdata = "blogdata.txt"
  end

  def pearson
    f = lambda{|v1, v2|
      sum1 = sum2 = sum1Sq = sum2Sq = pSum = result = 0
    
      v1.each{|x| sum1 += x}
      v2.each{|x| sum2 += x}
    
      v1.each{|x| sum1Sq += x**2}
      v2.each{|x| sum2Sq += x**2}
    
      for i in 0...v1.size
        pSum += v1[i] * v2[i]
      end
    
      num = pSum - (sum1 * sum2 / v1.size)
      den = Math.sqrt((sum1Sq - sum1**2/v1.size) * (sum2Sq - sum2**2/v1.size))

      if den != 0
        result = 1.0 - num/den
      end

      result
    }

    return f
  end

  def tanimoto
    f = lambda{|v1,v2|
      c1 = c2 = shr = result = 0
      for i in 0...v1.size
        if v1[i] != 0
          c1 += 1
        end
        if v2[i] != 0
          c2 += 1
        end
        if v1[i] != 0 && v2[i] != 0
          shr += 1
        end
      end
      result = 1.0 - shr/(c1+c2-shr)

      result
    }

    return f
  end
end
