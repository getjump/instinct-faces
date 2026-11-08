import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var far as BitmapResource or Null;
  hidden var near as BitmapResource or Null;
  hidden var band as BitmapResource or Null;
  hidden var frameArt as BitmapResource or Null;
  hidden var arch as Array<Array<Number>>;
  hidden const CX = [0, 7, 15, 22, 30, 37, 45, 52, 60, 60, 0];
  hidden const CY = [120, 116, 114, 113, 113, 113, 114, 116, 120, 136, 136];

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
    arch = new [11] as Array<Array<Number>>;
    for (var i = 0; i < 11; i++) {
      arch[i] = [0, 0];
    }
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    far = WatchUi.loadResource(Rez.Drawables.far) as BitmapResource;
    near = WatchUi.loadResource(Rez.Drawables.near) as BitmapResource;
    band = WatchUi.loadResource(Rez.Drawables.band) as BitmapResource;
    frameArt = WatchUi.loadResource(Rez.Drawables.frame) as BitmapResource;
  }

  hidden function dist() as String {
    var d = ActivityMonitor.getInfo().distance;
    if (d == null) {
      return "--";
    }
    var t = d / 10000;
    return (t / 10) + "." + (t % 10);
  }

  hidden function cadence() as String {
    var i = Activity.getActivityInfo();
    if (i != null && i.currentCadence != null) {
      return (i.currentCadence as Number).toString();
    }
    return "--";
  }

  function render(dc as Dc, n as Now) as Void {
    var ms = System.getTimer();
    var o1 = (ms * 5 / 1000) % 80;
    var o2 = (ms * 16 / 1000) % 60;
    var o3 = (ms * 40 / 1000) % 46;
    var o4 = (ms * 60 / 1000) % 12;
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 30, 32, G.L, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    G.t(dc, F.time, F.time_b, 30, 60, G.L, n.hhmm());
    dc.setClip(18, 70, 140, 66);
    dc.drawBitmap(18, 70, band as BitmapResource);
    for (var k = -1; k < 3; k++) {
      dc.drawBitmap(18 - o1 + 80 * k, 90, far as BitmapResource);
    }
    for (var k = -1; k < 4; k++) {
      var bx = 18 - o2 + 60 * k;
      G.paper(dc);
      for (var i = 0; i < 11; i++) {
        arch[i][0] = bx + CX[i];
        arch[i][1] = CY[i];
      }
      dc.fillPolygon(arch as Array<[Numeric, Numeric]>);
      dc.drawBitmap(bx, 112, near as BitmapResource);
    }
    G.ink(dc);
    for (var k = -1; k < 5; k++) {
      var px = 18 - o3 + 46 * k;
      dc.fillRectangle(px, 82, 2, 46);
      dc.fillRectangle(px - 3, 84, 8, 1);
      var lx = px + 1;
      var ly = 85;
      for (var s = 1; s <= 8; s++) {
        var t = s / 8.0;
        var x = px + 1 + 46 * t;
        var y = 85 + 16 * t * (1 - t);
        dc.drawLine(lx, ly, x, y);
        lx = x;
        ly = y;
      }
    }
    dc.fillRectangle(18, 128, 140, 8);
    G.paper(dc);
    for (var k = -1; k < 13; k++) {
      dc.fillRectangle(18 - o4 + 12 * k, 131, 6, 1);
    }
    dc.clearClip();
    G.ink(dc);
    dc.drawBitmap(14, 68, frameArt as BitmapResource);
    G.t(dc, F.lab, F.lab_b, 88, 156, G.C, "CADENCE " + cadence() + " SPM");
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "DIST");
    G.t(dc, F.dist, F.dist_b, 144, 44, G.C, dist());
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "KM");
  }
}
