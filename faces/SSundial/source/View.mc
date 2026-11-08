import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var dial as BitmapResource or Null;
  hidden var pen as BitmapResource or Null;
  hidden const RAD = 0.017453292519943295;

  function initialize() {
    BaseFace.initialize();
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    dial = WatchUi.loadResource(Rez.Drawables.dial) as BitmapResource;
    pen = WatchUi.loadResource(Rez.Drawables.pen) as BitmapResource;
  }

  hidden function atan2(y as Float, x as Float) as Float {
    if (x > 0.000001) {
      return Math.atan(y / x).toFloat();
    }
    if (x < -0.000001) {
      return (Math.atan(y / x) + (y >= 0 ? Math.PI : -Math.PI)).toFloat();
    }
    return (y >= 0 ? Math.PI / 2 : -Math.PI / 2).toFloat();
  }

  hidden function shadowAngle(sl as Float, hh as Float) as Float {
    var H = hh * 15 * RAD;
    return atan2(sl * Math.sin(H), Math.cos(H));
  }

  hidden function edgeX(ax as Float, ay as Float, bx as Float, by as Float, y as Float) as Float or Null {
    if ((ay <= y && by > y) || (by <= y && ay > y)) {
      return ax + (y - ay) * (bx - ax) / (by - ay);
    }
    return null;
  }

  hidden function rows(dc as Dc, p as Array<Float>) as Void {
    var y0 = p[1] < p[3] ? (p[1] < p[5] ? p[1] : p[5]) : (p[3] < p[5] ? p[3] : p[5]);
    var y1 = p[1] > p[3] ? (p[1] > p[5] ? p[1] : p[5]) : (p[3] > p[5] ? p[3] : p[5]);
    for (var y = Math.floor(y0).toNumber(); y <= Math.ceil(y1).toNumber(); y++) {
      var lo = 9999.0;
      var hi = -9999.0;
      for (var e = 0; e < 3; e++) {
        var a = e * 2;
        var b = ((e + 1) % 3) * 2;
        var x = edgeX(p[a], p[a + 1], p[b], p[b + 1], y + 0.5);
        if (x != null) {
          lo = x < lo ? x : lo;
          hi = x > hi ? x : hi;
        }
      }
      if (hi >= lo) {
        var xl = Math.round(lo).toNumber();
        var w = Math.round(hi).toNumber() - xl;
        if (w > 0 && y >= 54 && y < 116) {
          dc.setClip(xl, y, w, 1);
          dc.drawBitmap(30, 54, pen as BitmapResource);
        }
      }
    }
    dc.clearClip();
  }

  function render(dc as Dc, n as Now) as Void {
    var loc = D.location();
    var lat = 41.3;
    if (loc != null) {
      lat = (loc as Position.Location).toDegrees()[0];
    }
    var latR = lat * RAD;
    var sl = Math.sin(latR).toFloat();
    var doy = n.doy();
    var dec = -23.44 * RAD * Math.cos(2 * Math.PI * (doy + 10) / 365.0);
    var h = n.h + n.m / 60.0 + n.s / 3600.0;
    var noon = 12.0;
    var st = D.sunTimes();
    if (st != null) {
      var d = (st[0] + (st[1] - st[0]) / 2 - n.epoch) / 3600.0;
      d = d - 24 * Math.floor((d + 12) / 24);
      noon = h + d;
    }
    var H = (h - noon) * 15 * RAD;
    var sinAlt = Math.sin(latR) * Math.sin(dec) + Math.cos(latR) * Math.cos(dec) * Math.cos(H);
    sinAlt = sinAlt > 1 ? 1 : (sinAlt < -1 ? -1 : sinAlt);
    var alt = Math.asin(sinAlt);
    var up = alt > 0.01;
    var th = shadowAngle(sl, (h - noon).toFloat());
    var L = 0.0;
    if (up) {
      L = 14 / Math.tan(alt);
      L = L < 10 ? 10 : (L > 48 ? 48 : L);
    }
    var cx = 84;
    var cy = 108;
    var sn = Math.sin(th);
    var cs = Math.cos(th);
    dc.drawBitmap(28, 52, dial as BitmapResource);
    G.ink(dc);
    for (var k = 0; k <= 24; k++) {
      var off = 6 + k * 0.5 - noon;
      if (off < -6 || off > 6) {
        continue;
      }
      var a = shadowAngle(sl, off.toFloat());
      var r1 = k % 2 == 0 ? 40 : 46;
      dc.drawLine(cx + r1 * Math.sin(a), cy - r1 * Math.cos(a), cx + 52 * Math.sin(a), cy - 52 * Math.cos(a));
    }
    if (up) {
      rows(dc, [cx + 5 * cs, cy + 5 * sn, cx + (L + 5) * sn, cy - (L + 5) * cs, cx - 5 * cs, cy - 5 * sn] as Array<Float>);
      G.ink(dc);
      dc.fillPolygon([[cx + 2 * cs, cy + 2 * sn], [cx + L * sn, cy - L * cs], [cx - 2 * cs, cy - 2 * sn]] as Array<[Numeric, Numeric]>);
    }
    dc.fillRectangle(83, 72, 2, 36);
    dc.fillCircle(84, 108, 3);
    G.t(dc, F.time, F.time_b, 88, 146, G.C, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 88, 160, G.C, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "ALT");
    G.t(dc, F.alt, F.alt_b, 144, 44, G.C, (up ? Math.round(alt / RAD).toNumber() : 0).toString());
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "SOLAR");
    dc.drawCircle(158, 26, 2);
  }
}
