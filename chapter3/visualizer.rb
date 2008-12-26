require 'cairo'

# not implement
class Visualizer
  def drawdendrogram(clust, labels, png)
    format = Cairo::FORMAT_ARGB32
    h = getheight(clust) * 20
    w = 1200
    radius = h / Math::PI

    surface = Cairo::ImageSurface.new(format, w, h)
    context = Cairo::Context.new(surface)
 
    context.set_source_rgb(1, 1, 1)
    context.rectangle(0, 0, w, h)
    context.fill

    context.set_source_rgb(0, 0, 0)
    depth = getdepth(clust)
    scaling = (w-150) / depth

    drawline(context, 0, h/2, 10, h/2)
    drawnode(context, clust, 10, h/2, scaling, labels)
    surface.write_to_png(png)
  end

  def drawnode(context, clust, x, y, scaling, labels)
    if clust.id < 0
      h1 = getheight(clust.left) * 20
      h2 = getheight(clust.right) * 20
      top = y - (h1+h2)/2
      bottom = y + (h1+h2)/2
      
      p clust.distance
      ll = clust.distance * scaling
      drawline(context, x, top+h1/2, x, bottom-h2/2)
      drawline(context, x, top+h1/2, x+ll, top+h1/2)
      drawline(context, x, bottom-h2/2, x+ll, bottom-h2/2)

      drawnode(context, clust.left, x+ll, top+h1/2, scaling, labels)
      drawnode(context, clust.right, x+ll, bottom-h2/2, scaling, labels)
    else
      context.move_to(x+5, y)
      context.show_text(labels[clust.id])
    end
  end

  def drawline(context, start_x, start_y, end_x, end_y)
    context.move_to(start_x, start_y)
    context.line_to(end_x, end_y)
    context.stroke
  end

  def getheight(clust)
    if !clust.left && !clust.right
      return 1
    end

    return getheight(clust.left) + getheight(clust.right)
  end

  def getdepth(clust)
    if !clust.left && !clust.right
      return 0
    end

    return max(getdepth(clust.left),getdepth(clust.right)) + clust.distance
  end

  def max(x, y)
    if x > y
      return x
    else
      return y
    end
  end
end
