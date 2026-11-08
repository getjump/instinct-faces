import Toybox.Graphics;
import Toybox.Lang;
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
    G.t(dc, F.time, F.time_b, 88, 160, G.C, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 88, 171, G.C, U.dowU(n) + " " + U.p2(n.d));
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 22, G.C, "SET IN");
    G.t(dc, F.cd, F.cd_b, 144, 46, G.C, countdown(n));
  }

  hidden function countdown(n as Now) as String {
    var st = D.sunTimes();
    if (st == null) {
      return "--";
    }
    var left = st[1] - n.epoch;
    while (left < 0) {
      left += 86400;
    }
    while (left > 86400) {
      left -= 86400;
    }
    if (left < 3600) {
      return (left / 60) + "M";
    }
    return (left / 3600) + ":" + U.p2((left / 60) % 60);
  }
}
