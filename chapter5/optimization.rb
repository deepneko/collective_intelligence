class Optimization
  def initialize
    @people = [['Seymour', 'BOS'],
              ['Franny', 'DAL'],
              ['Zooney', 'CAK'],
              ['Walt', 'MIA'],
              ['Buddy', 'ORD'],
              ['Les', 'OMA']]

    @destination = 'LGA'

    @flights = []
    begin
      open('schedule.txt') { |file|
        @flights = Hash.new(){[]}
        while line = file.gets
          key = []
          value = []
          lines = line.split(/\s*,\s*/)
          key << lines.shift << lines.shift
          value << lines.shift << lines.shift << lines.shift.strip.to_i
          flights_value = @flights[key]
          @flights[key] = (flights_value << value)
        end
      }
    rescue
      print "can't read schedule.txt"
    end
  end

  def printschedule(r)
    for d in 0...r.size/2
      name = @people[d][0]
      origin = @people[d][1]
      o_d_pair = [origin, @destination]
      d_o_pair = [@destination, origin]
      out = @flights[o_d_pair][r[d*2]]
      ret = @flights[d_o_pair][r[d*2+1]]

      print "#{name}\t#{origin}\t#{out[0]}-#{out[1]} #{out[2]}\t#{ret[0]}-#{ret[1]} #{ret[2]}\n"
    end
  end

  def schedulecost
    f = lambda { |sol|
      totalprice = 0
      latestarrival = 0
      earliestdep = 24*60

      for d in 0...sol.size/2
        origin = @people[d][1]
        o_d_pair = [origin, @destination]
        d_o_pair = [@destination, origin]
        outbound = @flights[o_d_pair][sol[d*2]]
        returnf = @flights[d_o_pair][sol[d*2+1]]
        
        totalprice += outbound[2]
        totalprice += returnf[2]
        
        if latestarrival < getminutes(outbound[1])
          latestarrival = getminutes(outbound[1])
        end
        if earliestdep > getminutes(returnf[0])
          earliestdep = getminutes(returnf[0])
        end
      end
      
      totalwait = 0
      for d in 0...sol.size/2
        origin = @people[d][1]
        o_d_pair = [origin, @destination]
        d_o_pair = [@destination, origin]
        outbound = @flights[o_d_pair][sol[d*2]]
        returnf = @flights[d_o_pair][sol[d*2+1]]
        totalwait += latestarrival - getminutes(outbound[1])
        totalwait += getminutes(returnf[0]) - earliestdep
      end
      
      if latestarrival < earliestdep
        totalprice += 50
      end

      #p "schedule_cost " + (totalwait+totalprice).to_s
      totalwait + totalprice
    }

    return f
  end

  def randomoptimize(domain, &block)
    best = 999999999
    bestr = nil
    r = []
    
    for i in 0...1000
      r = []
      domain.each do |d|
        r << randint(d[0], d[1])
      end

      cost = block.call(r)
      if cost < best
        best = cost
        bestr = r;
      end
    end

    return r
  end

  def hillclimb(domain, &block)
    sol = []
    domain.each do |d|
      sol << randint(d[0], d[1])
    end

    while true
      neighbors = []
      for j in 0...domain.size
        if sol[j] > domain[j][0]
          n = []
          n << sol[0...j] << sol[j]-1 << sol[j+1...sol.size]
          neighbors << n.flatten
        end

        if sol[j] < domain[j][1]
          n = []
          n << sol[0...j] << sol[j]+1 << sol[j+1...sol.size]
          neighbors << n.flatten
        end
      end

      current = block.call(sol)
      best = current
      for j in 0...neighbors.size
        cost = block.call(neighbors[j])
        if cost < best
          best = cost
          sol = neighbors[j]
        end
      end

      if best == current
        break
      end
    end

    return sol
  end

  def annealingoptimize(domain, t=10000.0, cool=0.95, step=1, &block)
    vec = []
    domain.each do |d|
      vec << randint(d[0], d[1])
    end

    while t > 0.1
      i = randint(0, domain.size-1)
      dir = randint(-step, step)

      vecb = Marshal.load(Marshal.dump(vec))
      vecb[i] += dir
      if vecb[i] < domain[i][0]
        vecb[i] < domain[i][0]
      elsif vecb[i] > domain[i][1]
        vecb[i] = domain[i][1]
      end

      ea = block.call(vec)
      eb = block.call(vecb)
      p = Math::E ** -((eb-ea).abs/t)
      #print p.to_s + ":" + ((eb-ea).abs/t).to_s + "\n"

      if eb < ea || rand < p
        vec = vecb
      end

      t = t * cool
    end

    return vec
  end

  def geneticoptimize(domain, popsize=50, step=1, mutprob=0.2, elite=0.2, maxiter=100, &block)
    pop = []
    for i in 0...popsize
      vec = []
      domain.each do |d|
        vec << randint(d[0], d[1])
      end
      pop << vec
    end

    topelite = (elite * popsize).to_i

    for i in 0...maxiter.size
      scores = Hash.new
      pop.each do |v|
        scores[block.call(v)] = v
      end
      score_a = scores.to_a.sort{|a, b|
        (a[0] <=> b[0]) * 2 + (a[1] <=> b[1])
      }

      ranked = []
      score_a.each do |score|
        ranked << score[1]
      end

      pop = ranked[0...topelite-1]
      while pop.size < popsize
        if rand < mutprob
          c = randint(0, topelite)
          pop << mutate(ranked[c], domain, step)
        else
          c1 = randint(0, topelite)
          c2 = randint(0, topelite)
          pop << crossover(ranked[c1], ranked[c2], domain)
        end
      end

      p score_a[0][0]
    end

    return score_a[0][1]
  end

  def mutate(vec, domain, step)
    i = randint(0, domain.size-1)
    if rand < 0.5 && vec[i] > domain[i][0]
      v = []
      v << vec[0...i] << vec[i]-step << vec[i+1...vec.size]
      return v.flatten
    elsif vec[i] < domain[i][1]
      v = []
      v << vec[0...i] << vec[i]+step << vec[i+1...vec.size]
      return v.flatten
    end

    # 原本のプログラムだと絶対このreturn文が抜けてると思うのだが
    # pythonの仕様なのだろうか
    return vec
  end
  
  def crossover(r1, r2, domain)
    i = randint(1, domain.size-2)
    r = []
    r << r1[0...i] << r2[i...r2.size]
    return r.flatten
  end
  
  def randint(i1, i2)
    r = []
    for i in i1...i2+1
      r << i
    end

    return r.sort_by{rand}[0]
  end

  def getminutes(t)
    time = t.split(/\s*:\s*/)
    return time[0].to_i*60 + time[1].to_i
  end

  def people
    @people
  end
end

optimization = Optimization.new
#p optimization.getminutes("23:33")
#s = [1,4,3,2,7,3,6,3,2,4,5,3]

domain = Array.new(optimization.people.size*2){[0, 8]}
costf = optimization.schedulecost
#s = optimization.randomoptimize(domain, &costf)
#s = optimization.hillclimb(domain, &costf)
#s = optimization.annealingoptimize(domain, &costf)
s = optimization.geneticoptimize(domain, &costf)
optimization.printschedule(s)
