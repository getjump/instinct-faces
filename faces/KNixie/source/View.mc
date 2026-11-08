import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var dial as BitmapResource or Null;
  hidden var dg as BitmapResource or Null;
  hidden var ds as BitmapResource or Null;
  hidden var colon as BitmapResource or Null;
  hidden const CX = [31, 65, 107, 141];
  hidden var key as Number = -1;
  hidden var cyc as Number = 0;

  function initialize() {
    BaseFace.initialize();
    animMs = 150;
    partialBox = [113, 0, 62, 62];
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    dial = WatchUi.loadResource(Rez.Drawables.dial) as BitmapResource;
    dg = WatchUi.loadResource(Rez.Drawables.dg) as BitmapResource;
    ds = WatchUi.loadResource(Rez.Drawables.ds) as BitmapResource;
    colon = WatchUi.loadResource(Rez.Drawables.colon) as BitmapResource;
  }

  function step() as Void {
    if (cyc > 0) {
      cyc--;
    }
  }

  hidden function cell(dc as Dc, bmp as BitmapResource, k as Number, cw as Number, ch as Number, x as Number, y as Number) as Void {
    dc.setClip(x, y, cw, ch);
    dc.drawBitmap(x - k * cw, y, bmp);
    dc.clearClip();
  }

  function render(dc as Dc, n as Now) as Void {
    dc.drawBitmap(0, 0, dial as BitmapResource);
    var k = n.h * 60 + n.m;
    if (k != key) {
      cyc = (key >= 0 && awake) ? 6 : 0;
      key = k;
    }
    var d = [n.h / 10, n.h % 10, n.m / 10, n.m % 10];
    var adv = cyc > 0 ? ((6 - cyc) * 5) / 2 : 0;
    for (var i = 0; i < 4; i++) {
      var v = cyc > 0 ? (d[i] + adv + i * 3) % 10 : d[i];
      cell(dc, dg as BitmapResource, v, 32, 52, CX[i] - 16, 64);
    }
    if (!awake || n.s % 2 == 0) {
      dc.drawBitmap(80, 80, colon as BitmapResource);
    }
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 88, 142, G.C, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    sub(dc, n);
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    sub(dc, n);
  }

  hidden function sub(dc as Dc, n as Now) as Void {
    var live = secLive();
    var a = live ? n.s / 10 : 10;
    var b = live ? n.s % 10 : 10;
    cell(dc, ds as BitmapResource, a, 22, 40, 126, 12);
    cell(dc, ds as BitmapResource, b, 22, 40, 140, 12);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "SEC");
  }
}
