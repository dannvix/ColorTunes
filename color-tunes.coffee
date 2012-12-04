# color-tunes.coffee, Copyright 2012 Shao-Chung Chen.
# Licensed under the MIT license (http://www.opensource.org/licenses/mit-license.php)

class ColorTunes
  @getColorMap: (canvas, sx, sy, w, h, nc=8) ->
    pdata = canvas.getContext("2d").getImageData(sx, sy, w, h).data
    pixels = []
    for y in [sy...(sy + h)] by 1
      indexBase = (y * w * 4)
      for x in [sx...(sx + w)] by 1
        index = (indexBase + (x * 4))
        pixels.push [pdata[index], pdata[index+1], pdata[index+2]] # [r, g, b]
    (new MMCQ).quantize pixels, nc

  @colorDist: (a, b) ->
    square = (n) -> (n * n)
    (square(a[0] - b[0]) + square(a[1] - b[1]) + square(a[2] - b[2]))

  @fadeout: (canvas, width, height, opa=0.5, color=[0, 0, 0]) ->
    idata = canvas.getContext("2d").getImageData 0, 0, width, height
    pdata = idata.data
    for y in [0...height]
      for x in [0...width]
        idx = (y * width + x) * 4
        pdata[idx+0] = opa * pdata[idx+0] + (1 - opa) * color[0]
        pdata[idx+1] = opa * pdata[idx+1] + (1 - opa) * color[1]
        pdata[idx+2] = opa * pdata[idx+2] + (1 - opa) * color[2]
    canvas.getContext("2d").putImageData idata, 0, 0

  @feathering: (canvas, width, height, size=50, color=[0, 0, 0]) ->
    idata = canvas.getContext("2d").getImageData 0, 0, width, height
    pdata = idata.data

    conv = (x, y, p) ->
      p = 0 if p < 0
      p = 1 if p > 1
      idx = (y * width + x) * 4
      pdata[idx+0] = p * pdata[idx+0] + (1 - p) * color[0]
      pdata[idx+1] = p * pdata[idx+1] + (1 - p) * color[1]
      pdata[idx+2] = p * pdata[idx+2] + (1 - p) * color[2]

    dist = (xa, ya, xb, yb) ->
      Math.sqrt((xb-xa)*(xb-xa) + (yb-ya)*(yb-ya))
     
    for x in [0...width] by 1
      for y in [0...size] by 1
        p = y / size
        p = 1 - dist(x, y, size, size) / size if x < size
        conv x, y, p
    for y in [(0 + size)...height] by 1
      for x in [0...size] by 1
        p = x / size
        conv x, y, p
    canvas.getContext("2d").putImageData idata, 0, 0

  @mirror: (canvas, sy, height, color=[0, 0, 0]) ->
    width = canvas.width
    idata = canvas.getContext("2d").getImageData 0, (sy - height), width, (height * 2)
    pdata = idata.data
    for y in [height...(height * 2)] by 1
      for x in [0...width] by 1
        idx = (y * width + x) * 4
        idxu = ((height * 2 - y) * width + x) * 4
        p = (y - height) / height + 0.33
        p = 1 if p > 1
        pdata[idx+0] = (1 - p) * pdata[idxu+0] + p * color[0]
        pdata[idx+1] = (1 - p) * pdata[idxu+1] + p * color[1]
        pdata[idx+2] = (1 - p) * pdata[idxu+2] + p * color[2]
        pdata[idx+3] = 255
    canvas.getContext("2d").putImageData idata, 0, (sy - height)

  @launch: (image, canvas) ->
    $(image).on "load", ->
      image.height = Math.round (image.height * (300 / image.width))
      image.width = 300
      
      canvas.width = image.width
      canvas.height = image.height + 150
      canvas.getContext("2d").drawImage image, 0, 0, image.width, image.height

      bgColorMap = ColorTunes.getColorMap canvas, 0, 0, (image.width * 0.5), (image.height), 4
      bgPalette = bgColorMap.cboxes.map (cbox) -> { count: cbox.cbox.count(), rgb: cbox.color }
      bgPalette.sort (a, b) -> (b.count - a.count)
      bgColor = bgPalette[0].rgb

      fgColorMap = ColorTunes.getColorMap canvas, 0, 0, image.width, image.height, 10
      fgPalette = fgColorMap.cboxes.map (cbox) -> { count: cbox.cbox.count(), rgb: cbox.color }
      fgPalette.sort (a, b) -> (b.count - a. count)

      maxDist = 0
      for color in fgPalette
        dist = ColorTunes.colorDist bgColor, color.rgb
        if dist > maxDist
          maxDist = dist
          fgColor = color.rgb

      maxDist = 0
      for color in fgPalette
        dist = ColorTunes.colorDist bgColor, color.rgb
        if dist > maxDist and color.rgb != fgColor
          maxDist = dist
          fgColor2 = color.rgb

      ColorTunes.fadeout canvas, image.width, image.height, 0.5, bgColor
      ColorTunes.feathering canvas, image.width, image.height, 60, bgColor
      ColorTunes.mirror canvas, (image.height - 1), 150, bgColor

      rgbToCssString = (color) ->
        "rgb(#{color[0]}, #{color[1]}, #{color[2]})"

      $(".playlist").css "color", "#{rgbToCssString fgColor2}"
      $(".track-title").css "color", "#{rgbToCssString fgColor}"
      $(".playlist").css "background-color", "#{rgbToCssString bgColor}"
      $(".playlist-indicator").css "border-bottom-color", "#{rgbToCssString bgColor}"
