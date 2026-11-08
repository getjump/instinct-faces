import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var sky as BitmapResource or Null;
  hidden var tex as BitmapResource or Null;
  hidden const HILL1 = [[0, 124], [22, 116], [44, 121], [70, 110], [96, 118], [122, 108], [146, 116], [176, 111], [176, 176], [0, 176]];
  hidden const HILL2 = [[0, 142], [30, 132], [58, 138], [92, 126], [124, 134], [152, 128], [176, 132], [176, 176], [0, 176]];

  function initialize() {
    BaseFace.initialize();
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    sky = WatchUi.loadResource(Rez.Drawables.sky) as BitmapResource;
    tex = WatchUi.loadResource(Rez.Drawables.hilltex) as BitmapResource;
  }

  function render(dc as Dc, n as Now) as Void {
    dc.drawBitmap(0, 0, sky as BitmapResource);
    var f = dayFraction(n);
    if (f >= 0.0 && f <= 1.0) {
      var a = Math.PI * f;
      sun(dc, 88 - 70 * Math.cos(a), 122 - 50 * Math.sin(a));
    }
    G.paper(dc);
    dc.fillPolygon(HILL1 as Array<[Numeric, Numeric]>);
    dc.drawBitmap(0, 108, tex as BitmapResource);
    G.ink(dc);
    dc.fillPolygon(HILL2 as Array<[Numeric, Numeric]>);
    G.paper(dc);
    G.t(dc, F.time, F.time_b, 88, 163, G.C, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 88, 173, G.C, U.dowU(n) + " " + U.p2(n.d));
    var age = D.moonAge(n.epoch);
    G.moon(dc, 144, 28, 13, age / 29.530588853);
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, D.moonName(age) + " " + age.toNumber() + "D");
  }

  hidden function dayFraction(n as Now) as Float {
    var st = D.sunTimes();
    if (st != null) {
      return ((n.epoch - st[0]).toFloat() / (st[1] - st[0])).toFloat();
    }
    return ((n.h * 60 + n.m - 360) / 720.0).toFloat();
  }

  hidden function sun(dc as Dc, x as Numeric, y as Numeric) as Void {
    G.paper(dc);
    dc.fillCircle(x, y, 15);
    G.ink(dc);
    dc.setPenWidth(1);
    for (var i = 0; i < 8; i++) {
      G.ring(dc, x, y, 11, 14, i * 45);
    }
    dc.fillCircle(x, y, 7);
  }
}
