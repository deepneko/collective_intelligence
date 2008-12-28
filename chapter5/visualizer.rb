require 'rubygems'
require 'sqlite3'
require 'cairo'

class Visualizer
  def initialize
    @con = SQLite3::Database.new("twitter.db")
    @userlist = @con.execute('select screen_name from friendsmatrix').flatten

    sql = "select "
    @userlist.each do |u|
      sql += u + ","
    end
    sql = sql.slice(0, sql.size-1) + " from friendsmatrix"
    @matrix = @con.execute(sql)

    @domain = Array.new(@userlist.size*2){[10,770]}

    @links = []
    for i in 0...@userlist.size
      for j in 0...@matrix.size
        if @userlist[i] == @userlist[j]
          next
        end
        if @matrix[i][j]=="1" and @matrix[j][i]=="1"
          if !@links.index([@userlist[j], @userlist[i]])
            @links << [@userlist[i], @userlist[j]]
          end
        end
      end
    end
  end

  def domain
    @domain
  end

  def crosscount
    f = lambda { |v|
      loc = Hash.new
      total = 0
      for i in 0...@userlist.size
        loc[@userlist[i]] = [v[i*2], v[i*2+1]]
      end

      for i in 0...@links.size
        for j in i+1...@links.size
          x1 = loc[@links[i][0]][0]
          y1 = loc[@links[i][0]][1]
          x2 = loc[@links[i][1]][0]
          y2 = loc[@links[i][1]][1]
          x3 = loc[@links[j][0]][0]
          y3 = loc[@links[j][0]][1]
          x4 = loc[@links[j][1]][0]
          y4 = loc[@links[j][1]][1]

          den = (y4-y3)*(x2-x1) - (x4-x3)*(y2-y1)
          if den == 0
            next
          end

          ua = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)).to_f/den
          ub = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)).to_f/den
          if ua > 0 and ua < 1 and ub > 0 and ub < 1
            total += 1
          end
        end
      end

      for i in 0...@userlist.size
        for j in i+1...@userlist.size
          x1 = loc[@userlist[i]][0]
          y1 = loc[@userlist[i]][1]
          x2 = loc[@userlist[j]][0]
          y2 = loc[@userlist[j]][1]
          
          dist = Math.sqrt((x1-x2)**2 + (y1-y2)**2)
          if dist < 50
            total += 1.0 - dist/50.0
          end
        end
      end

      p total
      return total
    }

    return f
  end

  def drawnetwork(sol)
    w = 800
    h = 800

    format = Cairo::FORMAT_ARGB32
    surface = Cairo::ImageSurface.new(format, w, h)
    context = Cairo::Context.new(surface)

    context.set_source_rgb(1, 1, 1)
    context.rectangle(0, 0, w, h)
    context.fill

    context.set_source_rgb(0, 0, 0)
    pos = Hash.new
    for i in 0...@userlist.size
      pos[@userlist[i]] = [sol[i*2], sol[i*2+1]]
    end
    @links.each do |link|
      drawline(context, pos[link[0]][0], pos[link[0]][1], pos[link[1]][0], pos[link[1]][1])
    end

    context.set_source_rgb(1, 0, 0)
    pos.each_pair do |n, p|
      context.move_to(p[0]-10, p[1])
      context.show_text(n)
    end

    surface.write_to_png("network.png")
  end

  def drawline(context, start_x, start_y, end_x, end_y)
    context.move_to(start_x, start_y)
    context.line_to(end_x, end_y)
    context.stroke
  end
end

