import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var bg as BitmapResource or Null;
  hidden var shad as BitmapResource or Null;

  function initialize() {
    BaseFace.initialize();
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    bg = WatchUi.loadResource(Rez.Drawables.bg) as BitmapResource;
    shad = WatchUi.loadResource(Rez.Drawables.shad) as BitmapResource;
  }

  hidden function phaseName(age as Float) as String {
    if (age >= 27.68 || age < 1.85) {
      return "NEW";
    } else if (age < 5.54) {
      return "CRESC";
    } else if (age < 9.23) {
      return "1ST Q";
    } else if (age < 12.92) {
      return "GIBB";
    } else if (age < 16.61) {
      return "FULL";
    } else if (age < 20.3) {
      return "GIBB";
    } else if (age < 23.99) {
      return "3RD Q";
    }
    return "CRESC";
  }

  function render(dc as Dc, n as Now) as Void {
    var age = D.moonAge(n.epoch);
    var c = Math.cos(2 * Math.PI * age / 29.530588853);
    var waxing = age < 14.765294;
    dc.drawBitmap(0, 0, bg as BitmapResource);
    for (var dy = -56; dy <= 56; dy++) {
      var w = Math.sqrt(56 * 56 - dy * dy);
      var xl;
      var xr;
      if (waxing) {
        xl = 82 - w;
        xr = 82 + c * w;
      } else {
        xl = 82 - c * w;
        xr = 82 + w;
      }
      var a = Math.round(xl).toNumber();
      var b = Math.round(xr).toNumber();
      if (b > a) {
        dc.setClip(a, 100 + dy, b - a, 1);
        dc.drawBitmap(24, 44, shad as BitmapResource);
      }
    }
    dc.clearClip();
    G.paper(dc);
    G.t(dc, F.time, F.time_b, 30, 42, G.L, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 88, 168, G.C, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, phaseName(age));
    G.t(dc, F.ill, F.ill_b, 144, 44, G.C, Math.round((1 - c) * 50).toNumber() + "%");
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, age.toNumber() + "D");
  }
}
