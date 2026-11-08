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
    G.t(dc, F.time, F.time_b, 10, 78, G.L, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 12, 88, G.L, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    G.t(dc, F.lab, F.lab_b, 144, 22, G.C, "STEPS");
    G.t(dc, F.st, F.st_b, 144, 46, G.C, kfmt(D.steps()));
  }

  hidden function kfmt(v as Number) as String {
    if (v < 1000) {
      return v.toString();
    }
    if (v >= 10000) {
      return (v / 1000) + "K";
    }
    var t = (v + 50) / 100;
    return (t / 10) + "." + (t % 10) + "K";
  }
}
