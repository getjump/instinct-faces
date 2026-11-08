import Toybox.Graphics;
import Toybox.Lang;

class FaceView extends BaseFace {
  hidden const GLYPH = [
    [7, 5, 5, 5, 7], [2, 6, 2, 2, 7], [7, 1, 7, 4, 7], [7, 1, 7, 1, 7], [5, 5, 7, 1, 1],
    [7, 4, 7, 1, 7], [7, 4, 7, 5, 7], [7, 1, 2, 2, 2], [7, 5, 7, 5, 7], [7, 5, 7, 1, 7]
  ] as Array<Array<Number>>;
  hidden var cur as Array<Number>;
  hidden var prev as Array<Number>;
  hidden var mask as Array<Number>;
  hidden var seed as Number = 0;
  hidden var prog as Number = 484;
  hidden var lastMin as Number = -1;

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
    cur = new [22] as Array<Number>;
    prev = new [22] as Array<Number>;
    mask = new [22] as Array<Number>;
    for (var i = 0; i < 22; i++) {
      cur[i] = 0;
      prev[i] = 0;
      mask[i] = 0;
    }
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function step() as Void {
    if (prog < 484) {
      prog += 121;
    }
  }

  hidden function build(n as Now) as Void {
    var e = n.epoch / 60;
    var s = e * 7919;
    for (var r = 0; r < 22; r++) {
      var w = 0;
      for (var c = 0; c < 22; c++) {
        var h = (((r * 22 + c + 1) ^ s) * -1640531535) >> 13;
        w |= (h & 1) << c;
      }
      prev[r] = cur[r];
      cur[r] = w;
    }
    seed = s;
    for (var r = 0; r < 22; r++) {
      mask[r] = 0;
    }
    var col = 3;
    for (var k = 0; k < 5; k++) {
      var d = k == 0 ? n.h / 10 : (k == 1 ? n.h % 10 : (k == 3 ? n.m / 10 : (k == 4 ? n.m % 10 : -1)));
      if (d < 0) {
        mask[11] |= 1 << col;
        mask[13] |= 1 << col;
        col += 2;
      } else {
        for (var r = 0; r < 5; r++) {
          var g = GLYPH[d][r];
          mask[10 + r] |= (((g & 1) << 2) | (g & 2) | (g >> 2)) << col;
        }
        col += 4;
      }
    }
  }

  function render(dc as Dc, n as Now) as Void {
    if (n.m != lastMin) {
      var first = lastMin < 0;
      lastMin = n.m;
      build(n);
      prog = first || !awake ? 484 : 0;
    }
    G.ink(dc);
    dc.setPenWidth(2);
    for (var r = 0; r < 22; r++) {
      var y = r * 8;
      var a = cur[r];
      var b = prev[r];
      var m = mask[r];
      for (var c = 0; c < 22; c++) {
        if (c >= 14 && r <= 7) {
          continue;
        }
        var x = c * 8;
        if (((m >> c) & 1) != 0) {
          continue;
        }
        var bit = ((r * 22 + c < prog ? a : b) >> c) & 1;
        if (bit != 0) {
          dc.drawLine(x, y, x + 8, y + 8);
        } else {
          dc.drawLine(x + 8, y, x, y + 8);
        }
      }
    }
    dc.setPenWidth(1);
    for (var r = 10; r < 15; r++) {
      var m = mask[r];
      for (var c = 3; c < 20; c++) {
        if (((m >> c) & 1) != 0) {
          dc.fillRectangle(c * 8, r * 8, 8, 8);
        }
      }
    }
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, U.monU(n));
    G.t(dc, F.dd, F.dd_b, 144, 44, G.C, U.p2(n.d));
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, U.dowU(n));
  }
}
