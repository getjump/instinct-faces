import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var dial as BitmapResource or Null;
  hidden const HH = [[78, 46], [79.6, 100], [79, 114], [77, 114], [76.4, 100]];

  function initialize() {
    BaseFace.initialize();
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    dial = WatchUi.loadResource(Rez.Drawables.dial) as BitmapResource;
  }

  function render(dc as Dc, n as Now) as Void {
    dc.drawBitmap(0, 0, dial as BitmapResource);
    G.ink(dc);
    var h12 = (n.h % 12) + n.m / 60.0 + n.s / 3600.0;
    G.hand(dc, HH, 78, 102, h12 * 30);
    dc.fillCircle(78, 102, 3.5);
    G.paper(dc);
    dc.fillCircle(78, 102, 1.2);
    G.ink(dc);
    var mins = ((n.m + 2) / 5) * 5;
    var hh = n.h;
    if (mins == 60) {
      mins = 0;
      hh = (hh + 1) % 24;
    }
    G.t(dc, F.ap, F.ap_b, 88, 172, G.C, "~ " + hh + ":" + U.p2(mins));
    G.t(dc, F.dow, F.dow_b, 144, 20, G.C, U.dowU(n));
    G.t(dc, F.dd, F.dd_b, 144, 44, G.C, U.p2(n.d));
  }
}
