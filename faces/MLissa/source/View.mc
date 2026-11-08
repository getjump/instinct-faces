import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden const NP = 144;
  hidden var axes as BitmapResource or Null;
  hidden var px as Array<Number>;
  hidden var py as Array<Number>;
  hidden var delta as Float = 0.0;
  hidden var tp as Float = 0.0;

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
    px = new [NP + 1] as Array<Number>;
    py = new [NP + 1] as Array<Number>;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    axes = WatchUi.loadResource(Rez.Drawables.axes) as BitmapResource;
  }

  function step() as Void {
    delta += 0.15;
    tp += 0.12;
    if (tp > 6.2831853) {
      tp -= 6.2831853;
    }
  }

  function render(dc as Dc, n as Now) as Void {
    var a = n.h % 5 + 1;
    var b = n.m % 7 + 2;
    if (a == b) {
      b++;
    }
    dc.drawBitmap(0, 0, axes as BitmapResource);
    G.ink(dc);
    var k = 6.2831853 / NP;
    for (var i = 0; i <= NP; i++) {
      var tt = i * k;
      px[i] = (86 + 58 * Math.sin(a * tt + delta) + 0.5).toNumber();
      py[i] = (92 + 50 * Math.sin(b * tt) + 0.5).toNumber();
    }
    for (var i = 0; i < NP; i++) {
      dc.drawLine(px[i], py[i], px[i + 1], py[i + 1]);
    }
    dc.fillCircle(86 + 58 * Math.sin(a * tp + delta), 92 + 50 * Math.sin(b * tp), 3);
    G.paper(dc);
    dc.fillRectangle(57, 149, 63, 19);
    G.ink(dc);
    dc.drawRectangle(56, 148, 64, 20);
    G.t(dc, F.time, F.time_b, 88, 164, G.C, n.hhmm());
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "A:B");
    G.t(dc, F.ratio, F.ratio_b, 144, 44, G.C, a + ":" + b);
    var deg = (delta * 57.29578).toNumber() % 360;
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, deg + " DEG");
  }
}
