# quantize.coffee, Copyright 2012 Shao-Chung Chen.
# Licensed under the MIT license (http://www.opensource.org/licenses/mit-license.php)

# Basic CoffeeScript port of the (MMCQ) Modified Media Cut Quantization
# algorithm from the Leptonica library (http://www.leptonica.com/).
# Return a color map you can use to map original pixels to the reduced palette.
# 
# Rewritten from the JavaScript port (http://gist.github.com/1104622)
# developed by Nick Rabinowitz under the MIT license.

# example (pixels are represented in an array of [R,G,B] arrays)
#
# myPixels = [[190,197,190], [202,204,200], [207,214,210], [211,214,211], [205,207,207]]
# maxColors = 4
#
# cmap = MMCQ.quantize myPixels, maxColors
# newPalette = cmap.palette()
# newPixels = myPixels.map (p) -> cmap.map(p)

class PriorityQueue
  constructor: (@comparator) ->
    @contents = []
    @sorted = false
  sort: ->
    @contents.sort @comparator
    @sotred = true
  push: (obj) ->
    @contents.push obj
    @sorted = false
  peek: (index = (@contents.length - 1)) ->
    @sort() unless @sorted
    @contents[index]
  pop: ->
    @sort() unless @sorted
    @contents.pop()
  size: ->
    @contents.length
  map: (func) ->
    @contents.map func


class MMCQ
  @sigbits = 5
  @rshift = (8 - MMCQ.sigbits)

  constructor: ->
    @maxIterations = 1000
    @fractByPopulations = 0.75

  # private method
  getColorIndex = (r, g, b) ->
    (r << (2 * MMCQ.sigbits)) + (g << MMCQ.sigbits) + b

  class ColorBox
    constructor: (@r1, @r2, @g1, @g2, @b1, @b2, @histo) ->
    volume: (forced) ->
      @_volume = ((@r2 - @r1 + 1) * (@g2 - @g1 + 1) * (@b2 - @b1 + 1)) if !@_volume or forced
      @_volume
    count: (forced) ->
      if !@_count_set or forced
        numpix = 0
        for r in [@r1..@r2] by 1
          for g in [@g1..@g2] by 1
            for b in [@b1..@b2] by 1
              index = getColorIndex r, g, b
              numpix += (@histo[index] || 0)
        @_count_set = true
        @_count = numpix
      @_count
    copy: ->
      new ColorBox @r1, @r2, @g1, @g2, @b1, @b2, @histo
    average: (forced) ->
      if !@_average or forced
        mult = (1 << (8 - MMCQ.sigbits))
        total = 0; rsum = 0; gsum = 0; bsum = 0;
        for r in [@r1..@r2] by 1
          for g in [@g1..@g2] by 1
            for b in [@b1..@b2] by 1
              index = getColorIndex r, g, b
              hval = (@histo[index] || 0)
              total += hval
              rsum += (hval * (r + 0.5) * mult)
              gsum += (hval * (g + 0.5) * mult)
              bsum += (hval * (b + 0.5) * mult)
        if total
          @_average = [~~(rsum / total), ~~(gsum / total), ~~(bsum / total)]
        else
          @_average = [
            ~~(mult * (@r1 + @r2 + 1) / 2),
            ~~(mult * (@g1 + @g2 + 1) / 2),
            ~~(mult * (@b1 + @b2 + 1) / 2),
          ]
      @_average
    contains: (pixel) ->
      r = (pixel[0] >> MMCQ.rshift); g = (pixel[1] >> MMCQ.rshift); b = (pixel[2] >> MMCQ.rshift)
      ((@r1 <= r <= @r2) and (@g1 <= g <= @g2) and (@b1 <= b <= @b2))
 
     
  class ColorMap
    constructor: ->
      @cboxes = new PriorityQueue (a, b) ->
        va = (a.count() * a.volume()); vb = (b.count() * b.volume())
        if va > vb then 1 else if va < vb then (-1) else 0
    push: (cbox) ->
      @cboxes.push { cbox: cbox, color: cbox.average() }
    palette: ->
      @cboxes.map (cbox) -> cbox.color
    size: ->
      @cboxes.size()
    map: (color) ->
      for i in [0...(@cboxes.size())] by 1
        if @cboxes.peek(i).cbox.contains color
          return @cboxes.peek(i).color
        return @.nearest color
    cboxes: ->
      @cboxes
    nearest: (color) ->
      square = (n) -> n * n
      minDist = 1e9
      for i in [0...(@cboxes.size())] by 1
        dist = Math.sqrt(
          square(color[0] - @cboxes.peek(i).color[0]) +
          square(color[1] - @cboxes.peek(i).color[1]) +
          square(color[2] - @cboxes.peek(i).color[2]))
        if dist < minDist
          minDist = dist
          retColor = @cboxes.peek(i).color
      retColor

  # private method
  getHisto = (pixels) =>
    histosize = 1 << (3 * @sigbits)
    histo = new Array(histosize)
    for pixel in pixels
      r = (pixel[0] >> @rshift); g = (pixel[1] >> @rshift); b = (pixel[2] >> @rshift)
      index = getColorIndex r, g, b
      histo[index] = (histo[index] || 0) + 1
    histo

  # private method
  cboxFromPixels = (pixels, histo) =>
    rmin = 1e6; rmax = 0
    gmin = 1e6; gmax = 0
    bmin = 1e6; bmax = 0
    for pixel in pixels
      r = (pixel[0] >> @rshift); g = (pixel[1] >> @rshift); b = (pixel[2] >> @rshift)
      if r < rmin then rmin = r else if r > rmax then rmax = r
      if g < gmin then gmin = g else if g > gmax then gmax = g
      if b < bmin then bmin = b else if b > bmax then bmax = b
    new ColorBox rmin, rmax, gmin, gmax, bmin, bmax, histo

  # private method
  medianCutApply = (histo, cbox) -> 
    return unless cbox.count()
    return [cbox.copy()] if cbox.count() is 1

    rw = (cbox.r2 - cbox.r1 + 1)
    gw = (cbox.g2 - cbox.g1 + 1)
    bw = (cbox.b2 - cbox.b1 + 1)
    maxw = Math.max rw, gw, bw
  
    total = 0; partialsum = []; lookaheadsum = []
    if maxw is rw
      for r in [(cbox.r1)..(cbox.r2)] by 1
        sum = 0
        for g in [(cbox.g1)..(cbox.g2)] by 1
          for b in [(cbox.b1)..(cbox.b2)] by 1
            index = getColorIndex r, g, b
            sum += (histo[index] or 0)
        total += sum
        partialsum[r] = total
    else if maxw is gw
      for g in [(cbox.g1)..(cbox.g2)] by 1
        sum = 0
        for r in [(cbox.r1)..(cbox.r2)] by 1
          for b in [(cbox.b1)..(cbox.b2)] by 1
            index = getColorIndex r, g, b
            sum += (histo[index] or 0)
        total += sum
        partialsum[g] = total
    else # maxw is bw    
      for b in [(cbox.b1)..(cbox.b2)] by 1
        sum = 0
        for r in [(cbox.r1)..(cbox.r2)] by 1
          for g in [(cbox.g1)..(cbox.g2)] by 1
            index = getColorIndex r, g, b
            sum += (histo[index] or 0)
        total += sum
        partialsum[b] = total

    partialsum.forEach (d, i) ->
      lookaheadsum[i] = (total - d)

    doCut = (color) ->
      dim1 = (color + '1'); dim2 = (color + '2')
      for i in [(cbox[dim1])..(cbox[dim2])] by 1
        if partialsum[i] > (total / 2)
          cbox1 = cbox.copy(); cbox2 = cbox.copy()
          left = (i - cbox[dim1]); right = (cbox[dim2] - i)
          if left <= right
            d2 = Math.min (cbox[dim2] - 1), ~~(i + right / 2)
          else
            d2 = Math.max (cbox[dim1]), ~~(i - 1 - left / 2)

          # avoid 0-count boxes
          d2++ while !partialsum[d2]
          count2 = lookaheadsum[d2]
          count2 = lookaheadsum[--d2] while !count2 and partialsum[(d2 - 1)]
          # set dimensions
          cbox1[dim2] = d2
          cbox2[dim1] = (cbox1[dim2] + 1)
          console.log "cbox counts: #{cbox.count()}, #{cbox1.count()}, #{cbox2.count()}"
          return [cbox1, cbox2]

    return doCut "r" if maxw == rw
    return doCut "g" if maxw == gw
    return doCut "b" if maxw == bw

  quantize: (pixels, maxcolors) ->
    if (!pixels.length) or (maxcolors < 2) or (maxcolors > 256)
      console.log "invalid arguments"
      return false

    # get the beginning cbox from the colors
    histo = getHisto pixels
    cbox = cboxFromPixels pixels, histo
    pq = new PriorityQueue (a, b) -> 
      va = a.count(); vb = b.count()
      if va > vb then 1 else if va < vb then (-1) else 0
    pq.push cbox

    # inner function to do the iteration
    iter = (lh, target) =>
      ncolors = 1
      niters = 0
      while niters < @maxIterations
        cbox = lh.pop()
        unless cbox.count()
          lh.push cbox
          niters++
          continue
        # do the cut
        cboxes = medianCutApply histo, cbox
        cbox1 = cboxes[0]; cbox2 = cboxes[1]
        unless cbox1
          console.log "cbox1 not defined; shouldn't happen"
          return;
        lh.push cbox1
        if cbox2 # cbox2 can be null
          lh.push cbox2
          ncolors++
        return if (ncolors >= target)
        if (niters++) > @maxIterations
          console.log "infinite loop; perhaps too few pixels"
          return

    # first set of colors, sorted by population
    iter pq, (@fractByPopulations * maxcolors)

    # re-sort by the product of pixel occupancy times the size in color space
    pq2 = new PriorityQueue (a, b) ->
        va = (a.count() * a.volume()); vb = (b.count() * b.volume())
        if va > vb then 1 else if va < vb then (-1) else 0
    pq2.push pq.pop() while pq.size()
    
    # next set - generate the median cuts using the (npix * vol) sorting
    iter pq2, (maxcolors - pq2.size())

    # calculate the actual colors
    cmap = new ColorMap
    cmap.push pq2.pop() while pq2.size()
    
    cmap
