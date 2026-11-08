import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

class FaceView extends BaseFace {
  hidden var bx as Float = 88.0;
  hidden var by as Float = 108.0;
  hidden var vx as Float = 2.4;
  hidden var vy as Float = 1.3;
  hidden var ly as Float = 100.0;
  hidden var ry as Float = 100.0;
  hidden var rally as Number = 0;
  hidden var missL as Boolean = false;
  hidden var missR as Boolean = false;
  hidden var flash as Number = 0;
  hidden var lastMin as Number = -1;

  function initialize() {
    BaseFace.initialize();
    animMs = 200;
    Math.srand(new Now().epoch);
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function step() as Void {
    if (flash > 0) {
      flash--;
    }
    for (var k = 0; k < 4; k++) {
      sub();
    }
  }

  hidden function clampF(v as Float, lo as Float, hi as Float) as Float {
    return v < lo ? lo : (v > hi ? hi : v);
  }

  hidden function reset() as Void {
    missL = false;
    missR = false;
    rally = 0;
    bx = 87.0;
    by = 80.0 + Math.rand() % 50;
    vx = (Math.rand() % 2 == 0 ? -1.0 : 1.0) * 2.4;
    vy = ((Math.rand() % 100) / 100.0 - 0.5) * 2.6;
  }

  hidden function sub() as Void {
    bx += vx;
    by += vy;
    if (by < 70) {
      by = 70.0;
      vy = vy < 0 ? -vy : vy;
    }
    if (by > 143) {
      by = 143.0;
      vy = vy > 0 ? -vy : vy;
    }
    var away = by < 108 ? 130.0 : 70.0;
    var tl = missL && vx < 0 ? away : by - 6.5;
    var tr = missR && vx > 0 ? away : by - 6.5;
    ly = clampF(ly + clampF(tl - ly, -2.4, 2.4), 70.0, 130.0);
    ry = clampF(ry + clampF(tr - ry, -2.4, 2.4), 70.0, 130.0);
    if (!missL && vx < 0 && bx <= 31 && bx >= 25 && by + 3 >= ly && by <= ly + 16) {
      vx = -vx;
      vy += (by + 1.5 - (ly + 8)) * 0.12;
      rally++;
    }
    if (!missR && vx > 0 && bx + 3 >= 145 && bx + 3 <= 151 && by + 3 >= ry && by <= ry + 16) {
      vx = -vx;
      vy += (by + 1.5 - (ry + 8)) * 0.12;
      rally++;
    }
    vy = clampF(vy, -2.6, 2.6);
    if (vy > -0.5 && vy < 0.5) {
      vy = vy < 0 ? -0.5 : 0.5;
    }
    if (bx < 14 || bx > 162) {
      reset();
      flash = 4;
    }
  }

  function render(dc as Dc, n as Now) as Void {
    if (n.m != lastMin) {
      if (lastMin >= 0) {
        if (awake) {
          missL = true;
        } else {
          reset();
          ly = 100.0;
          ry = 100.0;
          bx = 88.0;
          by = 108.0;
        }
      }
      lastMin = n.m;
    }
    var flashing = awake && flash > 0;
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 30, 56, G.L, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    dc.fillRectangle(0, 67, 176, 2);
    dc.fillRectangle(0, 147, 176, 2);
    for (var y = 70; y < 146; y += 6) {
      dc.fillRectangle(88, y, 1, 3);
    }
    if (!(flashing && flash % 2 == 1)) {
      G.t(dc, F.score, F.score_b, 66, 100, G.C, U.p2(n.h));
      G.t(dc, F.score, F.score_b, 111, 100, G.C, U.p2(n.m));
    }
    dc.fillRectangle(28, ly.toNumber(), 3, 16);
    dc.fillRectangle(145, ry.toNumber(), 3, 16);
    dc.fillRectangle(bx.toNumber(), by.toNumber(), 3, 3);
    G.t(dc, F.lab, F.lab_b, 88, 162, G.C, flashing ? "POINT!" : "HOURS  VS  MINUTES");
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "RALLY");
    G.t(dc, F.num, F.num_b, 144, 44, G.C, (rally % 1000).toString());
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "HITS");
  }
}
