import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden const NAMES = ["WINTER", "SPRING", "SUMMER", "AUTUMN"] as Array<String>;
  hidden var bg as BitmapResource or Null = null;
  hidden var cur as Number = -1;
  hidden var t as Float = 0.0;

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function step() as Void {
    t += 0.25;
  }

  hidden function season(mon as Number) as Number {
    if (mon == 12 || mon < 3) {
      return 0;
    }
    return mon < 6 ? 1 : (mon < 9 ? 2 : 3);
  }

  hidden function load(s as Number) as Void {
    bg = null;
    var id = s == 0 ? Rez.Drawables.s0 : (s == 1 ? Rez.Drawables.s1 : (s == 2 ? Rez.Drawables.s2 : Rez.Drawables.s3));
    bg = WatchUi.loadResource(id) as BitmapResource;
    cur = s;
  }

  function render(dc as Dc, n as Now) as Void {
    var s = season(n.mon);
    if (s != cur) {
      load(s);
    }
    dc.drawBitmap(0, 0, bg as BitmapResource);
    if (s == 2) {
      G.ink(dc);
      dc.setPenWidth(1);
      var deg = (t * 40).toNumber();
      for (var k = 0; k < 8; k++) {
        G.ring(dc, 30, 44, 10, 13, deg + k * 45);
      }
    }
    if (s == 0) {
      G.paper(dc);
    } else {
      G.ink(dc);
    }
    for (var i = 0; i < 26; i++) {
      var x;
      var y;
      var w;
      var h;
      if (s == 0) {
        y = (i * 29) % 150 + ((8 + (i % 4) * 3) * t).toNumber();
        y = y % 150;
        x = (i * 41) % 170 + 3 + 3 * Math.sin(t * 0.9 + i);
        w = 2;
        h = 2;
      } else if (s == 1) {
        var fall = ((i * 13) % 84 + ((7 + (i % 3) * 2) * t).toNumber()) % 84;
        y = 66 + fall;
        x = 36 + (i * 23) % 68 + fall * 0.5 + 4 * Math.sin(t * 1.3 + i);
        w = 2;
        h = 1;
      } else if (s == 3) {
        var fall = ((i * 17) % 84 + ((12 + (i % 4) * 3) * t).toNumber()) % 84;
        y = 66 + fall;
        x = 36 + (i * 23) % 68 + 7 * Math.sin(t * 2 + i * 1.7);
        w = 3;
        h = 2;
      } else {
        break;
      }
      dc.fillRectangle((x + 0.5).toNumber(), y, w, h);
    }
    G.paper(dc);
    dc.fillRectangle(104, 76, 65, 41);
    G.ink(dc);
    dc.drawRectangle(104, 76, 65, 41);
    G.t(dc, F.time, F.time_b, 108, 102, G.L, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 108, 112, G.L, U.dowU(n) + " " + U.p2(n.d));
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.mon, F.mon_b, 144, 40, G.C, U.monU(n));
    G.t(dc, F.lab, F.lab_b, 144, 54, G.C, NAMES[s]);
  }
}
