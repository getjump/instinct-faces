import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden const NS = 64;
  hidden const HEART = [[144, 57], [139, 52], [139, 50], [141, 48], [143, 48], [144, 50], [145, 48], [147, 48], [149, 50], [149, 52]];
  hidden var back as BitmapResource or Null;
  hidden var buf as Array<Number>;
  hidden var n as Number = 0;
  hidden var lastMin as Number = -1;

  function initialize() {
    BaseFace.initialize();
    animMs = 500;
    buf = new [NS] as Array<Number>;
    var hr = D.hr();
    for (var i = 0; i < NS; i++) {
      buf[i] = hr;
    }
    if ((Toybox has :SensorHistory) && (SensorHistory has :getHeartRateHistory)) {
      var it = SensorHistory.getHeartRateHistory({:period => NS, :order => SensorHistory.ORDER_OLDEST_FIRST});
      if (it != null) {
        var k = 0;
        var s = it.next();
        while (s != null && k < NS) {
          var v = s.data;
          buf[k] = v == null ? (k > 0 ? buf[k - 1] : 0) : v.toNumber();
          k++;
          s = it.next();
        }
        if (k > 0 && k < NS) {
          var cp = new [NS] as Array<Number>;
          for (var i = 0; i < NS; i++) {
            cp[i] = i < NS - k ? buf[k - 1] : buf[i - (NS - k)];
          }
          for (var i = 0; i < k; i++) {
            cp[NS - k + i] = buf[i];
          }
          buf = cp;
        }
      }
    }
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    back = WatchUi.loadResource(Rez.Drawables.back) as BitmapResource;
  }

  hidden function push(v as Number) as Void {
    for (var i = 0; i < NS - 1; i++) {
      buf[i] = buf[i + 1];
    }
    buf[NS - 1] = v;
    n++;
  }

  function step() as Void {
    var h = D.hr();
    push(h > 0 ? h : buf[NS - 1]);
  }

  hidden function yOf(v as Number) as Float {
    if (v <= 0) {
      return 126.0;
    }
    var y = 124 - (v - 45) * 0.75;
    return (y < 62 ? 62 : (y > 126 ? 126 : y)).toFloat();
  }

  function render(dc as Dc, now as Now) as Void {
    if (!awake && now.m != lastMin) {
      var h = D.hr();
      push(h > 0 ? h : buf[NS - 1]);
    }
    lastMin = now.m;
    dc.drawBitmap(0, 0, back as BitmapResource);
    G.ink(dc);
    G.t(dc, F.time, F.time_b, 26, 50, G.L, now.hhmm());
    var off = (n * 2) % 16;
    for (var x = 130 - off; x > 0; x -= 16) {
      for (var y = 62; y <= 128; y += 4) {
        dc.drawPoint(x, y);
      }
    }
    var mn = 999;
    var mx = 0;
    var py = 0.0;
    for (var i = 0; i < NS; i++) {
      var v = buf[i];
      var y = yOf(v);
      if (i > 0) {
        dc.drawLine(2 + 2 * i, py, 4 + 2 * i, y);
      }
      py = y;
      if (v > 0) {
        mn = v < mn ? v : mn;
        mx = v > mx ? v : mx;
      }
    }
    dc.drawLine(130, 62, 130, py - 5);
    dc.fillPolygon([[130, py], [126, py - 5], [134, py - 5]] as Array<[Numeric, Numeric]>);
    G.t(dc, F.lab, F.lab_b, 88, 146, G.C, mx > 0 ? "MIN " + mn + "  MAX " + mx : "MIN --  MAX --");
    G.t(dc, F.lab, F.lab_b, 88, 160, G.C, U.dowU(now) + " " + U.p2(now.d) + " " + U.monU(now));
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    var bpm = buf[NS - 1];
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "BPM");
    G.t(dc, F.bpm, F.bpm_b, 144, 44, G.C, bpm > 0 ? bpm.toString() : "--");
    var on = true;
    if (awake && bpm > 0) {
      var period = 60000 / (bpm < 40 ? 40 : bpm);
      on = System.getTimer() % period < period * 35 / 100;
    }
    if (on) {
      dc.fillPolygon(HEART as Array<[Numeric, Numeric]>);
    }
  }
}
