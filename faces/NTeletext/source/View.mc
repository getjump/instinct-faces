import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.Weather;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var banner as BitmapResource or Null;

  function initialize() {
    BaseFace.initialize();
    animMs = 500;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    banner = WatchUi.loadResource(Rez.Drawables.banner) as BitmapResource;
  }

  hidden function stress() as String {
    if ((Toybox has :SensorHistory) && (SensorHistory has :getStressHistory)) {
      var it = SensorHistory.getStressHistory({:period => 1});
      if (it != null) {
        var s = it.next();
        if (s != null && s.data != null) {
          return (s.data as Float).toNumber().toString();
        }
      }
    }
    return "--";
  }

  hidden function bodyBatt() as String {
    if ((Toybox has :SensorHistory) && (SensorHistory has :getBodyBatteryHistory)) {
      var it = SensorHistory.getBodyBatteryHistory({:period => 1});
      if (it != null) {
        var s = it.next();
        if (s != null && s.data != null) {
          return (s.data as Float).toNumber().toString();
        }
      }
    }
    return "--";
  }

  hidden function nv(v as Numeric or Null, suffix as String) as String {
    return v == null ? "--" : v.toNumber() + suffix;
  }

  hidden function lines(si as Number) as Array<String> {
    if (si == 0) {
      var w = null;
      if (Toybox has :Weather) {
        w = Weather.getCurrentConditions();
      }
      if (w == null) {
        return ["WEATHER", "NOW -- RAIN --", "LOW -- HIGH --", "WIND -- M/S"];
      }
      return ["WEATHER", "NOW " + nv(w.temperature, "C") + " RAIN " + nv(w.precipitationChance, "%"),
        "LOW " + nv(w.lowTemperature, "C") + " HIGH " + nv(w.highTemperature, "C"), "WIND " + nv(w.windSpeed, " M/S")];
    }
    if (si == 1) {
      var hr = D.hr();
      return ["BODY STATUS", "HEART " + (hr > 0 ? hr.toString() : "--") + " BPM",
        "BATTERY " + D.batt() + " STRESS " + stress(), "BODY BATT " + bodyBatt()];
    }
    var g = D.stepGoal();
    var st = D.steps();
    var pct = st * 100 / g;
    var f = pct / 10;
    if (f > 10) {
      f = 10;
    }
    var bar = "[";
    for (var i = 0; i < 10; i++) {
      bar += i < f ? "#" : "-";
    }
    bar += "] " + pct + "%";
    var inf = ActivityMonitor.getInfo();
    return ["ACTIVITY", "STEPS " + st + "/" + g, bar, "FLOORS " + nv(inf.floorsClimbed, "") + " KCAL " + nv(inf.calories, "")];
  }

  function render(dc as Dc, n as Now) as Void {
    var si = (n.epoch / 5) % 3;
    var pg = awake && n.epoch % 5 == 0 ? 100 + (frame * 37 + n.s * 13) % 99 : 100;
    var searching = pg != 100;
    G.ink(dc);
    var clock = n.hhmm();
    if (awake) {
      clock += ":" + U.p2(n.s);
    }
    G.t(dc, F.vt, F.vt_b, 26, 40, G.L, "P" + pg + " " + clock);
    dc.drawBitmap(0, 48, banner as BitmapResource);
    G.ink(dc);
    if (!searching) {
      var ls = lines(si);
      for (var i = 0; i < 4; i++) {
        G.t(dc, F.vt, F.vt_b, 26, 84 + i * 14, G.L, ls[i]);
      }
      G.t(dc, F.vt, F.vt_b, 150, 140, G.R, (si + 1) + "/3");
    }
    var names = ["WX", "BODY", "STEP"];
    for (var i = 0; i < 3; i++) {
      var x = 36 + i * 36;
      G.ink(dc);
      if (i == si) {
        dc.fillRectangle(x, 146, 33, 13);
        G.paper(dc);
      } else {
        dc.drawRectangle(x, 146, 33, 13);
      }
      G.t(dc, F.lab, F.lab_b, x + 16, 155, G.C, names[i]);
    }
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "PAGE");
    G.t(dc, F.pg, F.pg_b, 144, 44, G.C, pg.toString());
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "TXT");
  }
}
