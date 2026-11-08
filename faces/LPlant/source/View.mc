import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden const FS = [0.22, 0.42, 0.6, 0.76] as Array<Float>;
  hidden const TH = [0.12, 0.3, 0.48, 0.64] as Array<Float>;
  hidden var scD as BitmapResource or Null;
  hidden var scN as BitmapResource or Null;
  hidden var fl as Array<BitmapResource or Null>;
  hidden var t as Float = 0.0;

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
    fl = [null, null, null, null, null, null] as Array<BitmapResource or Null>;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    scD = WatchUi.loadResource(Rez.Drawables.sc_d) as BitmapResource;
    scN = WatchUi.loadResource(Rez.Drawables.sc_n) as BitmapResource;
  }

  function step() as Void {
    t += 0.25;
  }

  hidden function flower(r as Number) as BitmapResource {
    var i = r - 3;
    if (fl[i] == null) {
      var id = i == 0 ? Rez.Drawables.fl3 : (i == 1 ? Rez.Drawables.fl4 : (i == 2 ? Rez.Drawables.fl5 : (i == 3 ? Rez.Drawables.fl6 : (i == 4 ? Rez.Drawables.fl7 : Rez.Drawables.fl8))));
      fl[i] = WatchUi.loadResource(id) as BitmapResource;
    }
    return fl[i] as BitmapResource;
  }

  hidden function quad(pts as Array<Array<Numeric>>, o as Number, x0 as Float, y0 as Float, x1 as Float, y1 as Float, x2 as Float, y2 as Float, n as Number) as Void {
    for (var k = 1; k <= n; k++) {
      var u = k.toFloat() / n;
      var v = 1.0 - u;
      pts[o + k - 1] = [v * v * x0 + 2 * v * u * x1 + u * u * x2, v * v * y0 + 2 * v * u * y1 + u * u * y2] as Array<Numeric>;
    }
  }

  function render(dc as Dc, n as Now) as Void {
    var h = n.h + n.m / 60.0;
    var p;
    if (h >= 7 && h < 17) {
      p = (h - 7) / 10.0 * 0.8;
    } else {
      var hn = h >= 17 ? h - 17 : h + 7;
      p = 0.8 + hn / 14.0 * 0.2;
    }
    var day = p < 0.8;
    var q = day ? p / 0.8 : 1.0;
    var g = day ? q * 1.15 : 1.0;
    if (g > 1.0) {
      g = 1.0;
    }
    var tt = awake ? t : 0.0;
    dc.drawBitmap(0, 0, (day ? scD : scN) as BitmapResource);
    G.ink(dc);
    var sunVis = day && q > 0.05 && q < 0.95;
    if (sunVis) {
      var sx = 26 + 66 * q;
      var sy = 70 - 46 * Math.sin(Math.PI * q);
      dc.fillCircle(sx, sy, 6);
      var deg = (tt * 46).toNumber();
      for (var k = 0; k < 8; k++) {
        G.ring(dc, sx, sy, 9, 12, deg + k * 45);
      }
    }
    G.t(dc, F.hm, F.hm_b, 24, 100, G.L, U.p2(n.h));
    G.t(dc, F.hm, F.hm_b, 24, 132, G.L, U.p2(n.m));
    G.t(dc, F.lab, F.lab_b, 24, 146, G.L, U.dowU(n) + " " + U.p2(n.d));
    var H = 18 + 74 * g;
    var s = Math.sin(tt * 1.7) * 2.5 * g;
    var topX = 100 + s * 1.6;
    var topY = 134 - H;
    dc.setPenWidth(2);
    var px = 100;
    var py = 134;
    for (var k = 1; k <= 8; k++) {
      var u = k / 8.0;
      var v = 1.0 - u;
      var x = v * v * 100 + 2 * v * u * (100 + s) + u * u * topX;
      var y = v * v * 134 + 2 * v * u * (134 - H / 2) + u * u * topY;
      dc.drawLine(px, py, x, y);
      px = x.toNumber();
      py = y.toNumber();
    }
    dc.setPenWidth(1);
    for (var i = 0; i < 4; i++) {
      var k = (g - TH[i]) / 0.18;
      k = k < 0 ? 0.0 : (k > 1 ? 1.0 : k);
      var L = 16 * k;
      if (L < 1) {
        continue;
      }
      var bx = 100 + s * 1.6 * FS[i] * FS[i];
      var by = 134 - H * FS[i];
      var w = Math.sin(tt * 1.7 + i) * 1.2 * k;
      var side = i % 2 == 0 ? -1 : 1;
      var pts = new [9] as Array<Array<Numeric>>;
      pts[0] = [bx, by] as Array<Numeric>;
      quad(pts, 1, bx, by, bx + side * L * 0.45, by - L * 0.55 + w, bx + side * L, by - L * 0.25 + w, 4);
      quad(pts, 5, bx + side * L, by - L * 0.25 + w, bx + side * L * 0.55, by + L * 0.12 + w, bx, by, 4);
      dc.fillPolygon(pts as Array<[Numeric, Numeric]>);
    }
    if (g >= 0.9) {
      var fr = (3 + 5 * ((g - 0.9) / 0.08 > 1.0 ? 1.0 : (g - 0.9) / 0.08) + 0.5).toNumber();
      var fx = (topX + 0.5).toNumber();
      var fy = (topY + 0.5).toNumber();
      G.paper(dc);
      dc.fillCircle(fx, fy, fr);
      G.ink(dc);
      dc.drawBitmap(fx - fr - 1, fy - fr - 1, flower(fr));
      dc.fillCircle(fx, fy, 3);
    }
    G.paper(dc);
    G.t(dc, F.lab, F.lab_b, 100, 151, G.C, (g * 100).toNumber() + "%");
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "SOLAR");
    G.t(dc, F.sol, F.sol_b, 144, 44, G.C, D.solar() + "%");
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, day ? "DAY" : "NIGHT");
  }
}
