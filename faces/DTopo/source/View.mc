import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
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
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 33, 35, G.L, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    G.t(dc, F.time, F.time_b, 88, 153, G.C, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "ALT");
    var a = altitude();
    G.t(dc, F.alt, F.alt_b, 144, 44, G.C, a == null ? "--" : (a as Number).toString());
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "M");
  }

  hidden function altitude() as Number or Null {
    var i = Activity.getActivityInfo();
    if (i != null && i.altitude != null) {
      return Math.round(i.altitude as Float).toNumber();
    }
    if (Toybox has :SensorHistory && SensorHistory has :getElevationHistory) {
      var it = SensorHistory.getElevationHistory({:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST});
      var s = it == null ? null : it.next();
      if (s != null && s.data != null) {
        return Math.round(s.data as Float).toNumber();
      }
    }
    return null;
  }
}
