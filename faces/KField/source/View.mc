import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var dial as BitmapResource or Null;
  hidden const HH = [[78, 102], [74.5, 97], [74.5, 76], [78, 70], [81.5, 76], [81.5, 97]];
  hidden const HI = [[78, 93], [76.5, 91], [76.5, 78], [78, 75], [79.5, 78], [79.5, 91]];
  hidden const MH = [[78, 102], [75.5, 97], [75.5, 58], [78, 51], [80.5, 58], [80.5, 97]];
  hidden const MI = [[78, 93], [77, 91], [77, 60], [78, 56], [79, 60], [79, 91]];
  hidden const SH = [[77.5, 47], [78.5, 47], [78.5, 113], [77.5, 113]];
  hidden const ST = [[76.5, 108], [79.5, 108], [79.5, 116], [76.5, 116]];

  function initialize() {
    BaseFace.initialize();
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    dial = WatchUi.loadResource(Rez.Drawables.dial) as BitmapResource;
  }

  function render(dc as Dc, n as Now) as Void {
    dc.drawBitmap(0, 0, dial as BitmapResource);
    var m = n.m + n.s / 60.0;
    var h = (n.h % 12) + n.m / 60.0;
    G.ink(dc);
    G.hand(dc, HH, 78, 102, h * 30);
    G.paper(dc);
    G.hand(dc, HI, 78, 102, h * 30);
    G.ink(dc);
    G.hand(dc, MH, 78, 102, m * 6);
    G.paper(dc);
    G.hand(dc, MI, 78, 102, m * 6);
    G.ink(dc);
    if (awake) {
      G.hand(dc, SH, 78, 102, n.s * 6);
      G.hand(dc, ST, 78, 102, n.s * 6);
    }
    dc.fillCircle(78, 102, 3);
    G.paper(dc);
    dc.fillCircle(78, 102, 1);
    G.ink(dc);
    G.t(dc, F.dd, F.dd_b, 144, 37, G.C, U.p2(n.d));
    G.t(dc, F.dow, F.dow_b, 144, 53, G.C, U.dowU(n));
  }
}
