import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden const HOME_LAT = 41.31;
  hidden const HOME_LON = 69.28;
  hidden const NAMES = ["TBILISI", "BELGRADE", "TOKYO", "SAKHALIN"] as Array<String>;
  hidden const LATS = [41.72, 44.79, 35.68, 46.96] as Array<Float>;
  hidden const LONS = [44.79, 20.45, 139.69, 142.74] as Array<Float>;
  hidden const ARROW = [[80, 66], [73, 108], [80, 101], [87, 108]] as Array<Array<Numeric>>;
  hidden var disc as BitmapResource or Null;
  hidden var curA as Float = 0.0;
  hidden var curD as Float = 0.0;
  hidden var tgtA as Float = 0.0;
  hidden var tgtD as Float = 0.0;
  hidden var seen as Boolean = false;

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    disc = WatchUi.loadResource(Rez.Drawables.disc) as BitmapResource;
  }

  function step() as Void {
    var da = tgtA - curA;
    while (da > 180.0) {
      da -= 360.0;
    }
    while (da < -180.0) {
      da += 360.0;
    }
    curA += da * 0.5;
    curD += (tgtD - curD) * 0.5;
  }

  hidden function geo(lat1 as Float, lon1 as Float, lat2 as Float, lon2 as Float) as Array<Float> {
    var r = Math.PI / 180.0;
    var p1 = lat1 * r;
    var p2 = lat2 * r;
    var dl = (lon2 - lon1) * r;
    var y = Math.sin(dl) * Math.cos(p2);
    var x = Math.cos(p1) * Math.sin(p2) - Math.sin(p1) * Math.cos(p2) * Math.cos(dl);
    var b = Math.atan2(y, x) / r;
    while (b < 0.0) {
      b += 360.0;
    }
    while (b >= 360.0) {
      b -= 360.0;
    }
    var s1 = Math.sin((p2 - p1) / 2);
    var s2 = Math.sin(dl / 2);
    var a = s1 * s1 + Math.cos(p1) * Math.cos(p2) * s2 * s2;
    var d = 2 * 6371.0 * Math.asin(Math.sqrt(a));
    return [b, d] as Array<Float>;
  }

  function render(dc as Dc, n as Now) as Void {
    var lat = HOME_LAT;
    var lon = HOME_LON;
    var here = false;
    var loc = D.location();
    if (loc != null) {
      var dg = (loc as Position.Location).toDegrees();
      lat = dg[0].toFloat();
      lon = dg[1].toFloat();
      here = true;
    }
    var idx = (n.epoch / 5) % 4;
    var g = geo(lat, lon, LATS[idx], LONS[idx]);
    tgtA = g[0];
    tgtD = g[1];
    if (!awake || !seen) {
      curA = tgtA;
      curD = tgtD;
      seen = true;
    }
    G.ink(dc);
    G.t(dc, F.time, F.time_b, 30, 42, G.L, n.hhmm());
    dc.drawBitmap(38, 58, disc as BitmapResource);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 80, 57, G.C, "N");
    G.ink(dc);
    dc.fillPolygon(G.rot(ARROW, 80, 100, curA) as Array<[Numeric, Numeric]>);
    G.paper(dc);
    var p = G.rot(ARROW, 80, 100, curA);
    for (var i = 0; i < 4; i++) {
      var q = p[(i + 1) % 4];
      dc.drawLine(p[i][0], p[i][1], q[0], q[1]);
    }
    dc.fillCircle(80, 100, 3);
    G.ink(dc);
    dc.drawCircle(80, 100, 3);
    G.t(dc, F.dist, F.dist_b, 126, 104, G.L, curD.toNumber().toString());
    G.t(dc, F.lab, F.lab_b, 126, 116, G.L, "KM");
    G.t(dc, F.lab, F.lab_b, 88, 156, G.C, NAMES[idx]);
    G.t(dc, F.lab, F.lab_b, 88, 167, G.C, "BRG " + (tgtA.toNumber() % 360));
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    var ns = lat >= 0 ? "N" : "S";
    var al = lat < 0 ? -lat : lat;
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "FROM");
    G.t(dc, F.from, F.from_b, 144, 44, G.C, here ? "HERE" : "TAS");
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, (al * 10).toNumber() / 10 + "." + (al * 10).toNumber() % 10 + ns);
  }
}
