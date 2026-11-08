import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var ground as BitmapResource or Null;
  hidden var rows as Array<Number>;

  function initialize() {
    BaseFace.initialize();
    animMs = 400;
    rows = [0x07E0, 0x1FF8, 0x3FFC, 0x7FFE, 0x73CE, 0xF3CF, 0xFFFF, 0xFFFF, 0xFBDF, 0xFC3F, 0x7FFE, 0x3FFC, 0x1818, 0x3C3C] as Array<Number>;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    ground = WatchUi.loadResource(Rez.Drawables.ground) as BitmapResource;
  }

  hidden function mood(n as Now) as Number {
    if (n.h < 7 || n.h >= 22) {
      return 2;
    }
    var pct = pctSteps();
    var exp = (n.h * 60 + n.m - 420) * 100 / 900;
    return pct + 15 < exp ? 1 : 0;
  }

  hidden function pctSteps() as Number {
    var p = D.steps() * 100 / D.stepGoal();
    return p > 100 ? 100 : p;
  }

  function render(dc as Dc, n as Now) as Void {
    var st = mood(n);
    var pct = pctSteps();
    var fr = awake ? frame : 0;
    var walking = st != 2;
    var f1 = walking && fr % 2 == 1;
    var closed = st == 2 || (awake && fr % 11 == 10);
    var petX = walking ? (52 + 28 * Math.sin(fr * 0.2) + 0.5).toNumber() : 60;
    var py = 106 - (f1 ? 2 : 0);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 28, 36, G.L, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    G.t(dc, F.time, F.time_b, 12, 74, G.L, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 24, 86, G.L, "STEP " + pct + " BATT " + D.batt());
    dc.drawBitmap(0, 149, ground as BitmapResource);
    rows[4] = closed ? 0x7FFE : 0x73CE;
    rows[8] = st == 1 ? 0xFE7F : (st == 2 ? 0xFFFF : 0xFBDF);
    rows[9] = st == 1 ? 0xFE7F : 0xFC3F;
    rows[12] = f1 ? 0x300C : 0x1818;
    rows[13] = f1 ? 0x781E : 0x3C3C;
    for (var r = 0; r < 14; r++) {
      var w = rows[r];
      var s = -1;
      for (var c = 0; c <= 16; c++) {
        var on = c < 16 && ((w >> (15 - c)) & 1) != 0;
        if (on && s < 0) {
          s = c;
        } else if (!on && s >= 0) {
          dc.fillRectangle(petX + s * 3, py + r * 3, (c - s) * 3, 3);
          s = -1;
        }
      }
    }
    if (st == 1) {
      var bx = petX + 50 > 132 ? 132 : petX + 50;
      dc.fillPolygon([[bx + 3, 106], [bx + 9, 106], [bx - 2, 112]] as Array<[Numeric, Numeric]>);
      G.paper(dc);
      dc.fillRectangle(bx, 94, 35, 13);
      G.ink(dc);
      dc.drawRectangle(bx, 94, 35, 13);
      G.t(dc, F.lab, F.lab_b, bx + 18, 103, G.C, "WALK!");
    }
    if (st == 2) {
      var z0 = (104 - (fr * 3) % 16).toNumber();
      var z1 = (104 - (fr * 3 + 6) % 16).toNumber();
      var z2 = (104 - (fr * 3 + 12) % 16).toNumber();
      G.t(dc, F.z8, F.z8_b, 108, z0, G.L, "Z");
      G.t(dc, F.z10, F.z10_b, 115, z1, G.L, "Z");
      G.t(dc, F.z12, F.z12_b, 123, z2, G.L, "Z");
    }
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    var hs = 0.9 + 0.05 * Math.sin(fr * 0.8);
    if (st == 0) {
      hs = fr % 2 == 1 ? 1.25 : 1.0;
    } else if (st == 1) {
      hs = 0.8;
    }
    dc.fillPolygon([
      [144, 30 + 6 * hs], [144 - 8 * hs, 30 - 2 * hs], [144 - 8 * hs, 30 - 5 * hs], [144 - 5 * hs, 30 - 8 * hs], [144 - 2 * hs, 30 - 8 * hs],
      [144, 30 - 5 * hs], [144 + 2 * hs, 30 - 8 * hs], [144 + 5 * hs, 30 - 8 * hs], [144 + 8 * hs, 30 - 5 * hs], [144 + 8 * hs, 30 - 2 * hs]
    ] as Array<[Numeric, Numeric]>);
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, st == 0 ? "HAPPY" : (st == 1 ? "HUNGRY" : "SLEEPY"));
  }
}
