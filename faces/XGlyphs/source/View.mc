import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden const GL = [
    [1, 5, 7, 3, 1],
    [0, 1, 7],
    [0, 1, 5, 3, 7, 8],
    [0, 2, 4, 8, 6],
    [0, 4, 2, 8],
    [2, 0, 3, 4, 8, 6],
    [1, 3, 6, 8, 5, 3],
    [0, 2, 7],
    [0, 2, 6, 8, 0],
    [8, 2, 0, 3, 5]
  ] as Array<Array<Number>>;
  hidden const XS = [15, 51, 97, 133] as Array<Number>;
  hidden const DXS = [55, 71, 93, 109] as Array<Number>;
  hidden const SXS = [128, 146] as Array<Number>;
  hidden var head as BitmapResource or Null;
  hidden var scan as BitmapResource or Null;
  hidden var prev as Array<Number> = [-1, -1, -1, -1] as Array<Number>;
  hidden var at as Array<Number> = [-99, -99, -99, -99] as Array<Number>;
  hidden var sprev as Array<Number> = [-1, -1] as Array<Number>;
  hidden var sat as Array<Number> = [-99, -99] as Array<Number>;
  hidden var hx as Float = 0.0;
  hidden var hy as Float = 0.0;
  hidden var sx as Float = 0.0;
  hidden var sy as Float = 0.0;

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
    partialBox = [113, 0, 62, 62];
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    head = WatchUi.loadResource(Rez.Drawables.head) as BitmapResource;
    scan = WatchUi.loadResource(Rez.Drawables.scan) as BitmapResource;
  }

  function onExitSleep() as Void {
    for (var i = 0; i < 4; i++) {
      at[i] = frame + i;
    }
    BaseFace.onExitSleep();
  }

  hidden function rd(v as Float) as Number {
    return (v + 0.5).toNumber();
  }

  hidden function glyph(dc as Dc, d as Number, x as Number, y as Number, s as Number, p as Float, pen as Number) as Void {
    var g = GL[d];
    var n = g.size();
    var px = new [n] as Array<Float>;
    var py = new [n] as Array<Float>;
    var total = 0.0;
    for (var i = 0; i < n; i++) {
      px[i] = (x + (g[i] % 3) * s).toFloat();
      py[i] = (y + (g[i] / 3) * s).toFloat();
      if (i > 0) {
        var ddx = px[i] - px[i - 1];
        var ddy = py[i] - py[i - 1];
        total += Math.sqrt(ddx * ddx + ddy * ddy);
      }
    }
    var r = s > 10 ? 1 : 0;
    for (var i = 0; i < 9; i++) {
      dc.fillRectangle(x + (i % 3) * s - r, y + (i / 3) * s - r, 1 + 2 * r, 1 + 2 * r);
    }
    sx = px[0];
    sy = py[0];
    hx = px[0];
    hy = py[0];
    dc.setPenWidth(pen);
    var rem = total * p;
    for (var i = 1; i < n && rem > 0; i++) {
      var ddx = px[i] - px[i - 1];
      var ddy = py[i] - py[i - 1];
      var l = Math.sqrt(ddx * ddx + ddy * ddy);
      var k = rem >= l ? 1.0 : rem / l;
      hx = px[i - 1] + ddx * k;
      hy = py[i - 1] + ddy * k;
      dc.drawLine(rd(px[i - 1]), rd(py[i - 1]), rd(hx), rd(hy));
      rem -= l;
    }
    dc.setPenWidth(1);
  }

  hidden function prog(f as Number, ticks as Number) as Float {
    if (!awake) {
      return 1.0;
    }
    var p = (frame - f + 1).toFloat() / ticks;
    return p < 0.0 ? 0.0 : (p > 1.0 ? 1.0 : p);
  }

  function render(dc as Dc, n as Now) as Void {
    var digits = [n.h / 10, n.h % 10, n.m / 10, n.m % 10];
    for (var i = 0; i < 4; i++) {
      if (prev[i] != digits[i]) {
        if (prev[i] >= 0) {
          at[i] = frame + i;
        }
        prev[i] = digits[i];
      }
    }
    var sd = [n.s / 10, n.s % 10];
    for (var i = 0; i < 2; i++) {
      if (sprev[i] != sd[i]) {
        sprev[i] = sd[i];
        sat[i] = frame;
      }
    }
    G.ink(dc);
    dc.drawBitmap(28, 44, head as BitmapResource);
    G.ink(dc);
    var decoded = "";
    var heads = [] as Array<Number>;
    for (var i = 0; i < 4; i++) {
      var p = prog(at[i], 4);
      glyph(dc, digits[i], XS[i], 75, 14, p, 3);
      dc.fillRectangle(rd(sx - 2.2), rd(sy - 2.2), 4, 4);
      if (p < 1.0) {
        heads.add(rd(hx));
        heads.add(rd(hy));
        decoded += (frame * 7 + i * 3) % 10;
      } else {
        decoded += digits[i];
      }
      if (i == 1) {
        decoded += ":";
      }
    }
    for (var i = 0; i < heads.size(); i += 2) {
      dc.drawCircle(heads[i], heads[i + 1], 3);
    }
    dc.fillPolygon([[88, 81], [91, 84], [88, 87], [85, 84]] as Array<[Numeric, Numeric]>);
    dc.fillPolygon([[88, 93], [91, 96], [88, 99], [85, 96]] as Array<[Numeric, Numeric]>);
    if (awake) {
      dc.drawBitmap(10, 62 + (frame % 10) * 46 / 10, scan as BitmapResource);
    }
    G.t(dc, F.dec, F.dec_b, 88, 118, G.C, decoded);
    var dd = [n.d / 10, n.d % 10, n.mon / 10, n.mon % 10];
    for (var i = 0; i < 4; i++) {
      glyph(dc, dd[i], DXS[i], 128, 6, 1.0, 1);
    }
    dc.fillRectangle(87, 139, 2, 2);
    G.t(dc, F.date, F.date_b, 88, 156, G.C, U.p2(n.d) + "·" + U.p2(n.mon) + " " + U.dowU(n));
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    sub(dc, n, true);
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    sub(dc, n, false);
  }

  hidden function sub(dc as Dc, n as Now, anim as Boolean) as Void {
    if (secLive()) {
      var sd = [n.s / 10, n.s % 10];
      for (var i = 0; i < 2; i++) {
        glyph(dc, sd[i], SXS[i], 13, 7, anim ? prog(sat[i], 2) : 1.0, 2);
      }
      G.t(dc, F.ss, F.ss_b, 144, 44, G.C, U.p2(n.s));
    } else {
      G.t(dc, F.ss, F.ss_b, 144, 44, G.C, "--");
    }
    G.t(dc, F.sec, F.sec_b, 144, 55, G.C, "SEC");
  }
}
