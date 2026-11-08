import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var dial as BitmapResource or Null;
  hidden const HS = [[76.8, 104], [76.8, 84], [79.2, 84], [79.2, 104]];
  hidden const HT = [[76.5, 76.5], [78, 70], [79.5, 76.5]];
  hidden const HC = [[78, 79.7], [78, 79.8]];
  hidden const MH = [[77.2, 106], [77.2, 56], [78, 49], [78.8, 56], [78.8, 106]];
  hidden const SS = [[77.5, 119], [78.5, 119], [78.5, 131], [77.5, 131]];

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
    if (awake) {
      G.hand(dc, SS, 78, 128, n.s * 6);
    }
    dc.fillCircle(78, 128, 1.5);
    var m = n.m + n.s / 60.0;
    var h = (n.h % 12) + m / 60.0;
    G.hand(dc, HS, 78, 102, h * 30);
    G.hand(dc, HT, 78, 102, h * 30);
    var c = G.rot(HC, 78, 102, h * 30);
    dc.fillCircle(c[0][0], c[0][1], 4.5);
    G.paper(dc);
    dc.fillCircle(c[1][0], c[1][1], 1.6);
    G.ink(dc);
    G.hand(dc, MH, 78, 102, m * 6);
    dc.fillCircle(78, 102, 2.5);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, U.dowU(n));
    G.t(dc, F.dd, F.dd_b, 144, 44, G.C, U.p2(n.d));
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, U.monU(n));
  }
}
