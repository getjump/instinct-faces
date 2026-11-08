import Toybox.Graphics;
import Toybox.Lang;

class FaceView extends BaseFace {
  hidden const P = 375;
  hidden var tl as Array<Number>;
  hidden var blink as Boolean = true;

  function initialize() {
    BaseFace.initialize();
    animMs = 500;
    tl = new [P] as Array<Number>;
    var stays = [20, 35, 15, 40, 25, 30];
    var gaps = [25, 30, 50, 20, 45, 40];
    var k = 0;
    var p = 0;
    while (p < P) {
      for (var i = 0; i < gaps[k % 6] && p < P; i++) {
        tl[p] = 0;
        p++;
      }
      for (var i = 0; i < stays[k % 6] && p < P; i++) {
        tl[p] = 1;
        p++;
      }
      k++;
    }
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function step() as Void {
    blink = !blink;
  }

  function render(dc as Dc, n as Now) as Void {
    var start = n.epoch / 86400 % P;
    if (awake) {
      start = (start + frame) % P;
    }
    var used = 0;
    G.ink(dc);
    for (var i = 0; i < 180; i++) {
      var x = 34 + (i % 18) * 6;
      var y = 76 + (i / 18) * 6;
      if (tl[(start + i) % P] == 1) {
        used++;
        dc.fillRectangle(x, y, 5, 5);
      } else {
        dc.fillRectangle(x + 2, y + 2, 1, 1);
      }
    }
    var inNow = tl[(start + 179) % P] == 1;
    var left = 90 - used;
    if (left < 0) {
      left = 0;
    }
    var on = !awake || blink;
    G.t(dc, F.lab, F.lab_b, 30, 40, G.L, n.hhmm());
    G.t(dc, F.big, F.big_b, 30, 68, G.L, left.toString());
    G.t(dc, F.lab, F.lab_b, 66, 58, G.L, "DAYS");
    G.t(dc, F.lab, F.lab_b, 66, 68, G.L, "LEFT");
    if (on) {
      dc.drawRectangle(135, 129, 7, 7);
    }
    if (used <= 90 || on) {
      G.t(dc, F.lab, F.lab_b, 88, 150, G.C, (used > 90 ? "OVERSTAY " : "USED ") + used + "/90");
    }
    G.t(dc, F.lab, F.lab_b, 88, 162, G.C, "WINDOW 180D");
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "ZONE");
    G.t(dc, F.zone, F.zone_b, 144, 44, G.C, inNow ? "IN" : "OUT");
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "TODAY");
  }
}
