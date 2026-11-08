import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

class FaceView extends BaseFace {
  hidden const NP = 61;
  hidden var ys as Array<Number>;
  hidden var poly as Array<Array<Numeric>>;
  hidden var cacheHour as Number = -1;

  function initialize() {
    BaseFace.initialize();
    ys = new [11 * NP] as Array<Number>;
    poly = new [NP + 2] as Array<Array<Numeric>>;
    for (var i = 0; i < NP + 2; i++) {
      poly[i] = [0, 0] as Array<Numeric>;
    }
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  hidden function val(x as Number, hh as Number) as Float {
    var s = 0.18 + 0.1 * Math.sin(x * 0.13 + hh * 1.7) + 0.08 * Math.sin(x * 0.37 + hh * 0.9);
    if (hh == 7 || hh == 18) {
      var a = (x - 88) / 16.0;
      s += 0.75 * Math.pow(Math.E, -a * a);
    }
    var b = (x - 40 - ((hh * 13) % 80)) / 3.0;
    s += 0.18 * Math.pow(Math.E, -b * b);
    if (hh < 6) {
      s *= 0.4;
    }
    return (s < 0 ? 0 : (s > 1 ? 1 : s)).toFloat();
  }

  hidden function fill(hour as Number) as Void {
    for (var i = 0; i < 11; i++) {
      var hh = (hour - 11 + i + 24) % 24;
      var base = 52 + i * 8;
      for (var k = 0; k < NP; k++) {
        ys[i * NP + k] = ((base - 22 * val(28 + k * 2, hh)) * 10).toNumber();
      }
    }
    cacheHour = hour;
  }

  function render(dc as Dc, n as Now) as Void {
    if (cacheHour != n.h) {
      fill(n.h);
    }
    var prog = (n.m * 60 + n.s) / 3600.0;
    var xEnd = 28 + 120 * prog;
    var px = 28;
    var py = 140.0;
    var last = 0.2;
    for (var i = 0; i < 12; i++) {
      var base = 52 + i * 8;
      var cnt = NP;
      var xe = 148;
      var hh = (n.h - 11 + i + 24) % 24;
      if (i == 11) {
        cnt = ((xEnd - 28) / 2).toNumber() + 1;
        xe = xEnd;
      }
      for (var k = 0; k < cnt; k++) {
        var y;
        if (i == 11) {
          last = val(28 + k * 2, hh);
          y = base - 22 * last;
          px = 28 + k * 2;
          py = y;
        } else {
          y = ys[i * NP + k] / 10.0;
        }
        var p = poly[k];
        p[0] = 28 + k * 2;
        p[1] = y;
      }
      var p1 = poly[cnt];
      p1[0] = xe;
      p1[1] = base + 8;
      var p2 = poly[cnt + 1];
      p2[0] = 28;
      p2[1] = base + 8;
      G.paper(dc);
      if (cnt >= 2) {
        dc.fillPolygon(sub(cnt + 2) as Array<[Numeric, Numeric]>);
      }
      G.ink(dc);
      if (i == 11) {
        dc.setPenWidth(2);
      }
      for (var k = 1; k < cnt; k++) {
        dc.drawLine(poly[k - 1][0], poly[k - 1][1], poly[k][0], poly[k][1]);
      }
      dc.setPenWidth(1);
    }
    dc.fillCircle(px, py, 2);
    G.t(dc, F.time, F.time_b, 88, 164, G.C, n.hhmm());
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    var hr = D.hr();
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "HR");
    G.t(dc, F.hr, F.hr_b, 144, 44, G.C, hr > 0 ? hr.toString() : "--");
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "BPM");
  }

  hidden function sub(c as Number) as Array<Array<Numeric>> {
    if (c == NP + 2) {
      return poly;
    }
    var out = new [c] as Array<Array<Numeric>>;
    for (var i = 0; i < c; i++) {
      out[i] = poly[i];
    }
    return out;
  }
}
