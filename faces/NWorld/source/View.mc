import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden const HOME_LAT = 41.31;
  hidden const HOME_LON = 69.28;
  hidden var day as BitmapResource or Null;
  hidden var night as BitmapResource or Null;

  function initialize() {
    BaseFace.initialize();
    animMs = 400;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    day = WatchUi.loadResource(Rez.Drawables.day) as BitmapResource;
    night = WatchUi.loadResource(Rez.Drawables.night) as BitmapResource;
  }

  hidden function wrap180(a as Float) as Float {
    while (a >= 180.0) {
      a -= 360.0;
    }
    while (a < -180.0) {
      a += 360.0;
    }
    return a;
  }

  function render(dc as Dc, n as Now) as Void {
    var rad = Math.PI / 180.0;
    var utcH = (n.epoch % 86400) / 3600.0;
    var decl = -23.44 * Math.cos(2 * Math.PI * (n.doy() + 10) / 365.0);
    var subLon = wrap180(-15.0 * (utcH - 12.0));
    var sd = Math.sin(decl * rad);
    var cd = Math.cos(decl * rad);
    if (sd < 0.0001 && sd > -0.0001) {
      sd = 0.0001;
    }
    dc.drawBitmap(22, 55, day as BitmapResource);
    for (var c = 0; c < 44; c++) {
      var lon = -180.0 + (c + 0.5) * (360.0 / 44.0);
      var thr = Math.atan(-cd * Math.cos((lon - subLon) * rad) / sd) / rad;
      var k = ((90.0 - thr) / (180.0 / 22.0) + 0.5).toNumber();
      if (k < 0) {
        k = 0;
      }
      if (k > 22) {
        k = 22;
      }
      var r0 = sd > 0 ? k : 0;
      var r1 = sd > 0 ? 22 : k;
      if (r1 > r0) {
        dc.setClip(22 + c * 3, 55 + r0 * 3, 3, (r1 - r0) * 3);
        dc.drawBitmap(22, 55, night as BitmapResource);
      }
    }
    dc.clearClip();
    G.ink(dc);
    dc.drawRectangle(21, 54, 134, 68);
    var sx = 22 + (subLon + 180.0) / 360.0 * 132;
    var sy = 55 + (90.0 - decl) / 180.0 * 66;
    G.paper(dc);
    dc.fillCircle(sx, sy, 3);
    G.ink(dc);
    dc.drawCircle(sx, sy, 3);
    for (var k = 0; k < 8; k++) {
      G.ring(dc, sx, sy, 5, 7, k * 45);
    }
    var lat = HOME_LAT;
    var lng = HOME_LON;
    var loc = D.location();
    if (loc != null) {
      var dg = (loc as Position.Location).toDegrees();
      lat = dg[0];
      lng = dg[1];
    }
    var hx = 22 + (lng + 180.0) / 360.0 * 132;
    var hy = 55 + (90.0 - lat) / 180.0 * 66;
    G.paper(dc);
    dc.fillCircle(hx, hy, awake && frame % 2 == 1 ? 5 : 3);
    G.ink(dc);
    dc.drawCircle(hx, hy, awake && frame % 2 == 1 ? 5 : 3);
    dc.fillCircle(hx, hy, 1);
    var cz = Math.sin(lat * rad) * sd + Math.cos(lat * rad) * cd * Math.cos((lng - subLon) * rad);
    if (cz > 1.0) {
      cz = 1.0;
    }
    if (cz < -1.0) {
      cz = -1.0;
    }
    var alt = Math.round(Math.asin(cz) / rad).toNumber();
    G.t(dc, F.lab, F.lab_b, 30, 46, G.L, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    G.t(dc, F.time, F.time_b, 88, 148, G.C, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 88, 160, G.C, "UTC " + U.p2(n.epoch % 86400 / 3600) + ":" + U.p2(n.epoch % 3600 / 60));
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, alt > 0 ? "DAY" : "NIGHT");
    G.t(dc, F.alt, F.alt_b, 144, 44, G.C, alt + "°");
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "SUN ALT");
  }
}
