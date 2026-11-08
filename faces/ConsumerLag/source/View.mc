import Toybox.Graphics;
import Toybox.Lang;

class FaceView extends BaseFace {
  function initialize() {
    BaseFace.initialize();
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function render(dc as Dc, n as Now) as Void {
    G.ink(dc);
    var steps = D.steps();
    var goal = D.stepGoal();
    var k = steps * 24 / goal;
    if (k > 24) {
      k = 24;
    }
    G.t(dc, F.lab, F.lab_b, 30, 38, G.L, "TOPIC: DAY");
    G.t(dc, F.lab, F.lab_b, 26, 52, G.L, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    G.t(dc, F.time, F.time_b, 24, 104, G.L, n.hhmm());
    for (var i = 0; i < 24; i++) {
      var x = 26 + i * 5;
      if (i < k) {
        dc.fillRectangle(x, 114, 4, 10);
      } else if (i == k) {
        dither(dc, x);
      } else {
        dc.drawRectangle(x, 114, 4, 10);
      }
    }
    if (k < 24) {
      var cx = 26 + k * 5;
      dc.fillRectangle(cx + 1, 127, 2, 1);
      dc.fillRectangle(cx, 128, 4, 1);
      dc.fillRectangle(cx - 1, 129, 6, 1);
    }
    G.t(dc, F.lab, F.lab_b, 26, 140, G.L, "OFFSET " + k);
    G.t(dc, F.lab, F.lab_b, 146, 140, G.R, "HWM 24");
    G.t(dc, F.lab, F.lab_b, 88, 151, G.C, "PRODUCED " + steps);
    var bd = D.battDays();
    G.t(dc, F.lab, F.lab_b, 88, 163, G.C, "RETENTION " + (bd > 0 ? bd + "D" : "--"));
    G.t(dc, F.lab, F.lab_b, 144, 22, G.C, "LAG");
    G.t(dc, F.lag, F.lag_b, 144, 47, G.C, lagStr(steps, goal));
    G.t(dc, F.lab, F.lab_b, 144, 57, G.C, "STEPS");
  }

  hidden function dither(dc as Dc, x as Number) as Void {
    for (var y = 114; y < 124; y++) {
      for (var px = x; px < x + 4; px++) {
        if (((px + y) & 1) == 0) {
          dc.drawPoint(px, y);
        }
      }
    }
  }

  hidden function lagStr(steps as Number, goal as Number) as String {
    var left = goal - steps;
    if (left < 0) {
      left = 0;
    }
    if (left < 1000) {
      return left.toString();
    }
    var t = (left + 50) / 100;
    return (t / 10) + "." + (t % 10) + "K";
  }
}
