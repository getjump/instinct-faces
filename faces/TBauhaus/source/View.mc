import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var base as BitmapResource or Null;
  hidden var tri as BitmapResource or Null;
  hidden var subd as BitmapResource or Null;
  hidden var subl as BitmapResource or Null;
  hidden const HR = [[67.5, 92], [76.5, 92], [76.5, 58], [67.5, 58]];
  hidden const HK = [[69, 92], [75, 92], [75, 58], [69, 58]];
  hidden const TR = [[110, 154], [144, 154], [127, 124]];

  function initialize() {
    BaseFace.initialize();
    partialBox = [113, 0, 62, 62];
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    base = WatchUi.loadResource(Rez.Drawables.base) as BitmapResource;
    tri = WatchUi.loadResource(Rez.Drawables.tri) as BitmapResource;
    subd = WatchUi.loadResource(Rez.Drawables.subd) as BitmapResource;
    subl = WatchUi.loadResource(Rez.Drawables.subl) as BitmapResource;
  }

  hidden function pt(a as Numeric, r as Numeric) as Array<Float> {
    var t = Math.toRadians(a);
    return [(72 + r * Math.sin(t)).toFloat(), (92 - r * Math.cos(t)).toFloat()];
  }

  function render(dc as Dc, n as Now) as Void {
    dc.drawBitmap(0, 0, base as BitmapResource);
    var ma = (n.m + n.s / 60.0) * 6;
    var w = new [8] as Array<Array<Float>>;
    w[0] = [72.0, 92.0];
    for (var i = 0; i < 7; i++) {
      w[i + 1] = pt(ma - 30 + i * 10, 46);
    }
    G.ink(dc);
    dc.fillPolygon(w as Array<[Numeric, Numeric]>);
    var ha = ((n.h % 12) + n.m / 60.0) * 30;
    G.paper(dc);
    G.hand(dc, HR, 72, 92, ha);
    G.ink(dc);
    G.hand(dc, HK, 72, 92, ha);
    G.paper(dc);
    dc.fillCircle(72, 92, 5);
    G.ink(dc);
    dc.setPenWidth(2);
    dc.drawCircle(72, 92, 5);
    dc.setPenWidth(1);
    G.paper(dc);
    dc.fillPolygon(TR as Array<[Numeric, Numeric]>);
    dc.drawBitmap(107, 121, tri as BitmapResource);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 66, 158, G.L, U.dowU(n) + " " + U.p2(n.d));
    if (awake) {
      var sa = n.s * 6;
      var sp = pt(sa, 50);
      var q = [[sp[0] - 5, sp[1] - 5], [sp[0] + 5, sp[1] - 5], [sp[0] + 5, sp[1] + 5], [sp[0] - 5, sp[1] + 5]];
      G.hand(dc, q as Array<Array<Numeric>>, sp[0], sp[1], sa);
    }
    G.t(dc, F.num, F.num_b, 130, 98, G.L, U.p2(n.h));
    G.t(dc, F.num, F.num_b, 130, 122, G.L, U.p2(n.m));
    sub(dc, n);
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    sub(dc, n);
  }

  hidden function sub(dc as Dc, n as Now) as Void {
    var live = secLive();
    G.ink(dc);
    G.t(dc, F.ss, F.ss_b, 144, 38, G.C, live ? U.p2(n.s) : "--");
    dc.drawBitmap(130, 44, subd as BitmapResource);
    var a = live ? 180 + 3 * n.s : 180;
    if (a < 360) {
      var pts = new [10] as Array<Array<Float>>;
      var k = 0;
      pts[k] = [144.0, 58.0];
      k++;
      var steps = 8;
      for (var i = 0; i <= steps; i++) {
        var t = Math.toRadians(a + (360 - a) * i / steps.toFloat());
        pts[k] = [(144 + 15 * Math.cos(t)).toFloat(), (58 + 15 * Math.sin(t)).toFloat()];
        k++;
      }
      G.paper(dc);
      dc.fillPolygon(pts as Array<[Numeric, Numeric]>);
      G.ink(dc);
    }
    dc.drawBitmap(128, 44, subl as BitmapResource);
  }
}
