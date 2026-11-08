import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Weather;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var base as BitmapResource or Null;

  function initialize() {
    BaseFace.initialize();
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    base = WatchUi.loadResource(Rez.Drawables.base) as BitmapResource;
  }

  function render(dc as Dc, n as Now) as Void {
    dc.drawBitmap(0, 0, base as BitmapResource);
    G.paper(dc);
    G.t(dc, F.time, F.time_b, 20, 74, G.L, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 88, 170, G.C, U.dowU(n) + " " + U.p2(n.d));
    G.ink(dc);
    var temp = "--";
    var rain = "--";
    if (Toybox has :Weather) {
      var c = Weather.getCurrentConditions();
      if (c != null) {
        var t = c.temperature;
        if (t != null && t > -100 && t < 100) {
          temp = Math.round(t).toNumber().toString();
        }
        if (c.precipitationChance != null) {
          rain = c.precipitationChance.toNumber() + "%";
        }
      }
    }
    G.t(dc, F.tmp, F.tmp_b, 141, 38, G.C, temp);
    G.t(dc, F.lab, F.lab_b, 142, 54, G.L, rain);
  }
}
