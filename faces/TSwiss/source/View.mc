import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var fs as Array<FontResource> or Null;
  hidden var fb as Array<Number> or Null;
  hidden var key as Number = -1;
  hidden var scr as Number = 0;
  hidden const LV = [36, 33, 30, 27, 23, 21, 19, 16];
  hidden const ONES = ["ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTEEN", "NINETEEN"];
  hidden const TENS = ["", "", "TWENTY", "THIRTY", "FORTY", "FIFTY"];

  function initialize() {
    BaseFace.initialize();
    animMs = 200;
    partialBox = [113, 0, 62, 62];
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    fs = [F.a0, F.a1, F.a2, F.a3, F.a4, F.a5, F.a6, F.a7] as Array<FontResource>;
    fb = [F.a0_b, F.a1_b, F.a2_b, F.a3_b, F.a4_b, F.a5_b, F.a6_b, F.a7_b] as Array<Number>;
  }

  function step() as Void {
    if (scr > 0) {
      scr--;
    }
  }

  hidden function scramble(w as String) as String {
    var cs = w.toCharArray();
    var out = "";
    for (var i = 0; i < cs.size(); i++) {
      var v = cs[i].toNumber();
      if (v == 45 || v == 39) {
        out += cs[i].toString();
      } else {
        out += (65 + Math.rand() % 26).toChar().toString();
      }
    }
    return out;
  }

  hidden function line(dc as Dc, w as String, mw as Number, y as Number) as Void {
    var len = w.length();
    if (len == 0) {
      return;
    }
    var ideal = mw / (len * 0.47);
    if (ideal > 36) {
      ideal = 36;
    }
    var target = len * 0.47 * ideal;
    var idx = 0;
    var nat = 0;
    for (idx = 0; idx < 7; idx++) {
      if (LV[idx] <= ideal) {
        nat = dc.getTextWidthInPixels(w, (fs as Array<FontResource>)[idx]);
        if (nat <= target + 1) {
          break;
        }
      }
    }
    var f = (fs as Array<FontResource>)[idx];
    var b = (fb as Array<Number>)[idx];
    nat = dc.getTextWidthInPixels(w, f);
    var cs = w.toCharArray();
    var gap = len > 1 ? (target - nat) / (len - 1.0) : 0.0;
    if (gap < 0) {
      gap = 0.0;
    }
    var x = 16.0;
    for (var i = 0; i < len; i++) {
      var c = cs[i].toString();
      dc.drawText(x, y - b, f, c, Graphics.TEXT_JUSTIFY_LEFT);
      x += dc.getTextWidthInPixels(c, f) + gap;
    }
  }

  function render(dc as Dc, n as Now) as Void {
    var h = n.h;
    var m = n.m;
    var k = h * 60 + m;
    if (k != key) {
      scr = (key >= 0 && awake) ? 3 : 0;
      key = k;
    }
    var hw = h < 20 ? ONES[h] : "TWENTY" + (h > 20 ? "-" + ONES[h - 20] : "");
    var l2 = "";
    var l3 = "";
    if (m == 0) {
      l2 = "O'CLOCK";
    } else if (m < 10) {
      l2 = "OH";
      l3 = ONES[m];
    } else if (m < 20) {
      l2 = ONES[m];
    } else {
      l2 = TENS[m / 10] + (m % 10 != 0 ? "-" : "");
      l3 = m % 10 != 0 ? ONES[m % 10] : "";
    }
    if (scr > 0) {
      hw = scramble(hw);
      l2 = scramble(l2);
      l3 = scramble(l3);
    }
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 34, 28, G.L, U.dowU(n) + " " + U.p2(n.d) + "." + U.p2(n.mon));
    line(dc, hw, 82, 64);
    line(dc, l2, 112, 102);
    line(dc, l3, 120, 134);
    dc.fillRectangle(16, 142, 138, 1);
    if (awake) {
      dc.fillRectangle(16, 144, 138 * n.s / 60, 3);
    }
    var loc = D.location();
    var lat = "--";
    if (loc != null) {
      var d = (loc as Position.Location).toDegrees()[0];
      var a = d < 0 ? -d : d;
      lat = a.format("%.1f") + (d < 0 ? "S" : "N");
    }
    G.t(dc, F.lab, F.lab_b, 40, 160, G.L, "LAT " + lat);
    sub(dc, n);
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    sub(dc, n);
  }

  hidden function sub(dc as Dc, n as Now) as Void {
    G.ink(dc);
    G.t(dc, F.ss, F.ss_b, 144, 46, G.C, secLive() ? U.p2(n.s) : "--");
    G.t(dc, F.lab, F.lab_b, 144, 57, G.C, "SEC");
  }
}
