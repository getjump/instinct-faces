import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden const WX = [36, 58, 124, 140] as Array<Number>;
  hidden var bg as BitmapResource or Null;
  hidden var sand as BitmapResource or Null;
  hidden var t as Float = 0.0;
  hidden var goalDays as Number = 0;
  hidden var lastMin as Number = -1;

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    bg = WatchUi.loadResource(Rez.Drawables.bg) as BitmapResource;
    sand = WatchUi.loadResource(Rez.Drawables.sand) as BitmapResource;
  }

  function step() as Void {
    t += 0.25;
  }

  hidden function countDays() as Number {
    var c = 0;
    var info = ActivityMonitor.getInfo();
    if (info.steps != null && info.stepGoal != null && info.stepGoal > 0 && info.steps >= info.stepGoal) {
      c++;
    }
    var h = ActivityMonitor.getHistory();
    if (h != null) {
      for (var i = 0; i < h.size(); i++) {
        var s = h[i].steps;
        var g = h[i].stepGoal;
        if (s != null && g != null && g > 0 && s >= g) {
          c++;
        }
      }
    }
    return c;
  }

  hidden function weed(dc as Dc, x as Number, k as Number) as Void {
    var s1 = 4 * Math.sin(t * 1.2 + k);
    var s2 = 5 * Math.sin(t * 1.2 + k + 0.8);
    var top = k % 2 == 1 ? 104 : 96;
    var px = x;
    var py = 150;
    for (var i = 1; i <= 12; i++) {
      var u = (i % 6) / 6.0;
      if (i == 6) {
        u = 1.0;
      }
      var v = 1.0 - u;
      var qx;
      var qy;
      if (i <= 6) {
        qx = v * v * x + 2 * v * u * (x + s1) + u * u * x;
        qy = v * v * 150 + 2 * v * u * 135 + u * u * 122;
      } else {
        qx = v * v * x + 2 * v * u * (x - s1) + u * u * (x + s2);
        qy = v * v * 122 + 2 * v * u * 110 + u * u * top;
      }
      dc.drawLine(px, py, qx, qy);
      px = qx.toNumber();
      py = qy.toNumber();
    }
  }

  function render(dc as Dc, n as Now) as Void {
    if (n.m != lastMin) {
      lastMin = n.m;
      goalDays = countDays();
    }
    dc.drawBitmap(0, 0, bg as BitmapResource);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 34, 30, G.L, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    G.t(dc, F.time, F.time_b, 24, 56, G.L, n.hhmm());
    var px = 0;
    var py = 62;
    for (var x = 0; x <= 176; x += 4) {
      var y = 62 + 1.5 * Math.sin(x / 9.0 + t * 1.5);
      if (x > 0) {
        dc.drawLine(px, py, x, y);
      }
      px = x;
      py = y.toNumber();
    }
    dc.setPenWidth(2);
    for (var k = 0; k < 4; k++) {
      weed(dc, WX[k], k);
    }
    dc.setPenWidth(1);
    dc.drawBitmap(0, 144, sand as BitmapResource);
    for (var i = 0; i < 8; i++) {
      var bx = 40 + i * 13 + 2 * Math.sin(t * 2 + i);
      var by = 146 - ((t * 12 + i * 17).toNumber() % 84);
      G.ink(dc);
      dc.fillCircle(bx, by, 2);
      G.paper(dc);
      dc.fillCircle(bx, by, 1);
    }
    for (var i = 0; i < 5; i++) {
      var sp = 0.25 + i * 0.06;
      var ph = i * 1.3;
      var xx = 85 + 55 * Math.sin(t * sp + ph);
      var dir = Math.cos(t * sp + ph) > 0 ? 1 : -1;
      var yy = 80 + i * 12 + 3 * Math.sin(t * 1.3 + i);
      G.ink(dc);
      dc.fillEllipse(xx, yy, 6, 3);
      dc.fillPolygon([[xx - dir * 5, yy], [xx - dir * 11, yy - 4], [xx - dir * 11, yy + 4]] as Array<[Numeric, Numeric]>);
      G.paper(dc);
      dc.fillRectangle((xx + dir * 3 + 0.5).toNumber(), (yy - 1.5 + 0.5).toNumber(), 1, 1);
    }
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "GOAL");
    G.t(dc, F.num, F.num_b, 144, 44, G.C, goalDays.toString());
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "DAYS");
  }
}
