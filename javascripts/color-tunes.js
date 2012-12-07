// Generated by CoffeeScript 1.3.3
var ColorTunes;

ColorTunes = (function() {

  function ColorTunes() {}

  ColorTunes.getColorMap = function(canvas, sx, sy, w, h, nc) {
    var index, indexBase, pdata, pixels, x, y, _i, _j, _ref, _ref1;
    if (nc == null) {
      nc = 8;
    }
    pdata = canvas.getContext("2d").getImageData(sx, sy, w, h).data;
    pixels = [];
    for (y = _i = sy, _ref = sy + h; _i < _ref; y = _i += 1) {
      indexBase = y * w * 4;
      for (x = _j = sx, _ref1 = sx + w; _j < _ref1; x = _j += 1) {
        index = indexBase + (x * 4);
        pixels.push([pdata[index], pdata[index + 1], pdata[index + 2]]);
      }
    }
    return (new MMCQ).quantize(pixels, nc);
  };

  ColorTunes.colorDist = function(a, b) {
    var square;
    square = function(n) {
      return n * n;
    };
    return square(a[0] - b[0]) + square(a[1] - b[1]) + square(a[2] - b[2]);
  };

  ColorTunes.fadeout = function(canvas, width, height, opa, color) {
    var idata, idx, pdata, x, y, _i, _j;
    if (opa == null) {
      opa = 0.5;
    }
    if (color == null) {
      color = [0, 0, 0];
    }
    idata = canvas.getContext("2d").getImageData(0, 0, width, height);
    pdata = idata.data;
    for (y = _i = 0; 0 <= height ? _i < height : _i > height; y = 0 <= height ? ++_i : --_i) {
      for (x = _j = 0; 0 <= width ? _j < width : _j > width; x = 0 <= width ? ++_j : --_j) {
        idx = (y * width + x) * 4;
        pdata[idx + 0] = opa * pdata[idx + 0] + (1 - opa) * color[0];
        pdata[idx + 1] = opa * pdata[idx + 1] + (1 - opa) * color[1];
        pdata[idx + 2] = opa * pdata[idx + 2] + (1 - opa) * color[2];
      }
    }
    return canvas.getContext("2d").putImageData(idata, 0, 0);
  };

  ColorTunes.feathering = function(canvas, width, height, size, color) {
    var conv, dist, idata, p, pdata, x, y, _i, _j, _k, _l, _ref;
    if (size == null) {
      size = 50;
    }
    if (color == null) {
      color = [0, 0, 0];
    }
    idata = canvas.getContext("2d").getImageData(0, 0, width, height);
    pdata = idata.data;
    conv = function(x, y, p) {
      var idx;
      if (p < 0) {
        p = 0;
      }
      if (p > 1) {
        p = 1;
      }
      idx = (y * width + x) * 4;
      pdata[idx + 0] = p * pdata[idx + 0] + (1 - p) * color[0];
      pdata[idx + 1] = p * pdata[idx + 1] + (1 - p) * color[1];
      return pdata[idx + 2] = p * pdata[idx + 2] + (1 - p) * color[2];
    };
    dist = function(xa, ya, xb, yb) {
      return Math.sqrt((xb - xa) * (xb - xa) + (yb - ya) * (yb - ya));
    };
    for (x = _i = 0; _i < width; x = _i += 1) {
      for (y = _j = 0; _j < size; y = _j += 1) {
        p = y / size;
        if (x < size) {
          p = 1 - dist(x, y, size, size) / size;
        }
        conv(x, y, p);
      }
    }
    for (y = _k = _ref = 0 + size; _k < height; y = _k += 1) {
      for (x = _l = 0; _l < size; x = _l += 1) {
        p = x / size;
        conv(x, y, p);
      }
    }
    return canvas.getContext("2d").putImageData(idata, 0, 0);
  };

  ColorTunes.mirror = function(canvas, sy, height, color) {
    var idata, idx, idxu, p, pdata, width, x, y, _i, _j, _ref;
    if (color == null) {
      color = [0, 0, 0];
    }
    width = canvas.width;
    idata = canvas.getContext("2d").getImageData(0, sy - height, width, height * 2);
    pdata = idata.data;
    for (y = _i = height, _ref = height * 2; _i < _ref; y = _i += 1) {
      for (x = _j = 0; _j < width; x = _j += 1) {
        idx = (y * width + x) * 4;
        idxu = ((height * 2 - y) * width + x) * 4;
        p = (y - height) / height + 0.33;
        if (p > 1) {
          p = 1;
        }
        pdata[idx + 0] = (1 - p) * pdata[idxu + 0] + p * color[0];
        pdata[idx + 1] = (1 - p) * pdata[idxu + 1] + p * color[1];
        pdata[idx + 2] = (1 - p) * pdata[idxu + 2] + p * color[2];
        pdata[idx + 3] = 255;
      }
    }
    return canvas.getContext("2d").putImageData(idata, 0, sy - height);
  };

  ColorTunes.launch = function(image, canvas) {
    return $(image).on("load", function() {
      var bgColor, bgColorMap, bgPalette, color, dist, fgColor, fgColor2, fgColorMap, fgPalette, maxDist, rgbToCssString, _i, _j, _len, _len1;
      image.height = Math.round(image.height * (300 / image.width));
      image.width = 300;
      canvas.width = image.width;
      canvas.height = image.height + 150;
      canvas.getContext("2d").drawImage(image, 0, 0, image.width, image.height);
      bgColorMap = ColorTunes.getColorMap(canvas, 0, 0, image.width * 0.5, image.height, 4);
      bgPalette = bgColorMap.cboxes.map(function(cbox) {
        return {
          count: cbox.cbox.count(),
          rgb: cbox.color
        };
      });
      bgPalette.sort(function(a, b) {
        return b.count - a.count;
      });
      bgColor = bgPalette[0].rgb;
      fgColorMap = ColorTunes.getColorMap(canvas, 0, 0, image.width, image.height, 10);
      fgPalette = fgColorMap.cboxes.map(function(cbox) {
        return {
          count: cbox.cbox.count(),
          rgb: cbox.color
        };
      });
      fgPalette.sort(function(a, b) {
        return b.count - a.count;
      });
      maxDist = 0;
      for (_i = 0, _len = fgPalette.length; _i < _len; _i++) {
        color = fgPalette[_i];
        dist = ColorTunes.colorDist(bgColor, color.rgb);
        if (dist > maxDist) {
          maxDist = dist;
          fgColor = color.rgb;
        }
      }
      maxDist = 0;
      for (_j = 0, _len1 = fgPalette.length; _j < _len1; _j++) {
        color = fgPalette[_j];
        dist = ColorTunes.colorDist(bgColor, color.rgb);
        if (dist > maxDist && color.rgb !== fgColor) {
          maxDist = dist;
          fgColor2 = color.rgb;
        }
      }
      ColorTunes.fadeout(canvas, image.width, image.height, 0.5, bgColor);
      ColorTunes.feathering(canvas, image.width, image.height, 60, bgColor);
      ColorTunes.mirror(canvas, image.height - 1, 150, bgColor);
      rgbToCssString = function(color) {
        return "rgb(" + color[0] + ", " + color[1] + ", " + color[2] + ")";
      };
      $(".playlist").css("background-color", "" + (rgbToCssString(bgColor)));
      $(".playlist-indicator").css("border-bottom-color", "" + (rgbToCssString(bgColor)));
      $(".album-title, .track-title").css("color", "" + (rgbToCssString(fgColor)));
      return $(".album-artist, .album-tracks").css("color", "" + (rgbToCssString(fgColor2)));
    });
  };

  return ColorTunes;

})();
