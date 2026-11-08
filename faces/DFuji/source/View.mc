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
    G.ink(dc);
    G.t(dc, F.time, F.time_b, 112, 100, G.L, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "TYO");
    var t = (n.epoch + 32400) % 86400;
    G.t(dc, F.sub, F.sub_b, 144, 42, G.C, U.p2(t / 3600) + ":" + U.p2((t / 60) % 60));
    G.paper(dc);
    G.t(dc, F.lab, F.lab_b, 88, 168, G.C, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
  }
}
