import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.Time;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden const NB = 121;
  hidden var dith as BitmapResource or Null;
  hidden var back as BitmapResource or Null;
  hidden var bins as Array<Number>;
  hidden var cacheKey as Number = -1;

  function initialize() {
    BaseFace.initialize();
    bins = new [NB] as Array<Number>;
    for (var i = 0; i < NB; i++) {
      bins[i] = 0;
    }
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    back = WatchUi.loadResource(Rez.Drawables.back) as BitmapResource;
    dith = WatchUi.loadResource(Rez.Drawables.dith) as BitmapResource;
  }

  hidden function load(n as Now) as Void {
    var secs = n.h * 3600 + n.m * 60 + n.s;
    var mid = n.epoch - secs;
    var got = new [NB] as Array<Number>;
    for (var i = 0; i < NB; i++) {
      got[i] = -1;
    }
    if ((Toybox has :SensorHistory) && (SensorHistory has :getSolarIntensityHistory)) {
      var it = SensorHistory.getSolarIntensityHistory({:period => new Time.Duration(secs), :order => SensorHistory.ORDER_OLDEST_FIRST});
      if (it != null) {
        var s = it.next();
        while (s != null) {
          var v = s.data;
          if (v != null && s.when != null) {
            var k = ((s.when.value() - mid) / 720).toNumber();
            if (k >= 0 && k < NB) {
              var iv = v.toNumber();
              iv = iv < 0 ? 0 : (iv > 100 ? 100 : iv);
              if (iv > got[k]) {
                got[k] = iv;
              }
            }
          }
          s = it.next();
        }
      }
    }
    var prev = 0;
    for (var i = 0; i < NB; i++) {
      if (got[i] < 0) {
        got[i] = prev;
      }
      prev = got[i];
    }
    bins = got;
  }

  hidden function model(h as Float) as Float {
    if (h < 7.2 || h > 17.2) {
      return 0.0;
    }
    var b = Math.sin(Math.PI * (h - 7.2) / 10);
    var c = 0.78 + 0.22 * Math.sin(h * 3.1 + 1) * Math.sin(h * 1.7);
    var v = b * c;
    return (v < 0 ? 0 : v).toFloat();
  }

  function render(dc as Dc, n as Now) as Void {
    var key = n.h * 60 + n.m;
    if (key != cacheKey) {
      cacheKey = key;
      load(n);
    }
    var h = n.h + n.m / 60.0 + n.s / 3600.0;
    var cur = D.solar();
    var xn = 20 + h * 136 / 24;
    var nb = (h / 0.2).toNumber() + 1;
    nb = nb > NB ? NB : nb;
    dc.drawBitmap(0, 0, back as BitmapResource);
    G.ink(dc);
    G.t(dc, F.time, F.time_b, 26, 52, G.L, n.hhmm());
    var xi = xn.toNumber();
    dc.setClip(20, 70, xi - 19, 70);
    dc.drawBitmap(20, 70, dith as BitmapResource);
    dc.clearClip();
    var sum = 0;
    G.paper(dc);
    for (var i = 0; i < nb; i++) {
      var x0 = (20 + i * 0.2 * 136 / 24).toNumber();
      var x1 = (20 + (i + 1) * 0.2 * 136 / 24).toNumber();
      x1 = x1 > xi ? xi : x1;
      var top = 140 - bins[i] * 70 / 100;
      if (x1 > x0 && top > 70) {
        dc.fillRectangle(x0, 70, x1 - x0, top - 70);
      }
      sum += bins[i];
    }
    G.ink(dc);
    dc.setPenWidth(2);
    var px = 20;
    var py = 140 - bins[0] * 70 / 100;
    for (var i = 1; i < nb; i++) {
      var x = 20 + i * 0.2 * 136 / 24;
      var y = 140 - bins[i] * 70 / 100;
      dc.drawLine(px, py, x, y);
      px = x;
      py = y;
    }
    var cy = 140 - cur * 70 / 100;
    dc.drawLine(px, py, xn, cy);
    dc.setPenWidth(1);
    for (var x = xi + 3; x <= 156; x += 3) {
      var hh = (x - 20) * 24.0 / 136;
      dc.drawPoint(x, 140 - model(hh) * 70);
    }
    dc.drawLine(xi, 66, xi, 140);
    G.paper(dc);
    dc.fillCircle(xi, cy, 3);
    G.ink(dc);
    dc.setPenWidth(2);
    dc.drawCircle(xi, cy, 3);
    dc.setPenWidth(1);
    var mins = (sum * 0.2 * 9 / 100).toNumber();
    G.t(dc, F.lab, F.lab_b, 88, 164, G.C, "TODAY +" + mins + " MIN");
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "SUN");
    G.t(dc, F.cur, F.cur_b, 144, 44, G.C, cur + "%");
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "NOW");
  }
}
