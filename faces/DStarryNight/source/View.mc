import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
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
    G.t(dc, F.time, F.time_b, 16, 76, G.L, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 18, 88, G.L, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    G.t(dc, F.lab, F.lab_b, 144, 22, G.C, "TO DAWN");
    var st = D.sunTimes();
    var rise = "--:--";
    var cd = "--";
    if (st != null) {
      var r = st[0];
      var i = Time.Gregorian.info(new Time.Moment(r), Time.FORMAT_SHORT);
      rise = U.p2(i.hour) + ":" + U.p2(i.min);
      var left = r - n.epoch;
      while (left < 0) {
        left += 86400;
      }
      while (left > 86400) {
        left -= 86400;
      }
      cd = (left / 3600) + ":" + U.p2((left / 60) % 60);
    }
    G.t(dc, F.lab, F.lab_b, 88, 164, G.C, "SUNRISE " + rise);
    G.t(dc, F.cd, F.cd_b, 144, 46, G.C, cd);
  }
}
