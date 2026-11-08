import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var dial as BitmapResource or Null;
  hidden var bez as BitmapResource or Null;
  hidden var t0 as Number;
  hidden var bi as Number;
  hidden const BZ = [Rez.Drawables.b0, Rez.Drawables.b1, Rez.Drawables.b2, Rez.Drawables.b3, Rez.Drawables.b4, Rez.Drawables.b5, Rez.Drawables.b6, Rez.Drawables.b7, Rez.Drawables.b8, Rez.Drawables.b9, Rez.Drawables.b10, Rez.Drawables.b11];
  hidden const HH = [[76, 104], [76, 82], [72, 82], [78, 70], [84, 82], [80, 82], [80, 104]];
  hidden const HI = [[77.2, 98], [77.2, 83], [78, 80.5], [78.8, 83], [78.8, 98]];
  hidden const MH = [[76.5, 104], [76.5, 64], [78, 56], [79.5, 64], [79.5, 104]];
  hidden const MI = [[77.5, 98], [77.5, 65], [78, 61], [78.5, 65], [78.5, 98]];
  hidden const SH = [[77.5, 58], [78.5, 58], [78.5, 112], [77.5, 112]];
  hidden const ST = [[76.5, 106], [79.5, 106], [79.5, 113], [76.5, 113]];

  function initialize() {
    BaseFace.initialize();
    partialBox = [113, 0, 62, 62];
    var n = new Now();
    t0 = n.epoch;
    bi = ((n.m + 2) / 5) % 12;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    dial = WatchUi.loadResource(Rez.Drawables.dial) as BitmapResource;
    bez = WatchUi.loadResource(BZ[bi]) as BitmapResource;
  }

  function render(dc as Dc, n as Now) as Void {
    dc.drawBitmap(0, 0, dial as BitmapResource);
    dc.drawBitmap(20, 44, bez as BitmapResource);
    var m = n.m + n.s / 60.0;
    var h = (n.h % 12) + m / 60.0;
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
      var c = G.rot([[78, 69]], 78, 102, n.s * 6);
      dc.fillCircle(c[0][0], c[0][1], 2.8);
      G.paper(dc);
      dc.fillCircle(c[0][0], c[0][1], 1.1);
      G.ink(dc);
    }
    dc.fillCircle(78, 102, 3);
    sub(dc, n);
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    sub(dc, n);
  }

  hidden function sub(dc as Dc, n as Now) as Void {
    var el = n.epoch - t0;
    if (el < 0) {
      el = 0;
    }
    var ss = secLive() ? U.p2(el % 60) : "--";
    var d = (180 + 40 * Math.sin(n.epoch / 3.0)).toNumber();
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "DIVE");
    G.t(dc, F.el, F.el_b, 144, 43, G.C, (el / 60) + ":" + ss);
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, (d / 10) + "." + (d % 10) + "M");
  }
}
