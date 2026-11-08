import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.StringUtil;

class FaceView extends BaseFace {
  hidden const BASE = [
    "########################",
    "#..........#...~~~~....#",
    "#..TT......+...~~~~..>.#",
    "#..TT......#.......T...#",
    "#####+######..TT.......#",
    "#......#.......TT...####",
    "#......#....~~.........#",
    "#......+....~~...T.....#",
    "########################"
  ] as Array<String>;
  hidden const PX = [2, 3, 4, 5, 6, 6, 7, 8, 9, 10, 11, 11, 11, 12, 12, 12, 13, 14, 15, 16, 17, 18, 18, 19, 20, 20, 21, 21] as Array<Number>;
  hidden const PY = [6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 6, 5, 5, 4, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 3, 3, 2] as Array<Number>;
  hidden var walk as Number = 0;

  function initialize() {
    BaseFace.initialize();
    animMs = 400;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function onExitSleep() as Void {
    walk = 0;
    BaseFace.onExitSleep();
  }

  function step() as Void {
    walk++;
  }

  function render(dc as Dc, n as Now) as Void {
    var len = PX.size();
    var goal = D.stepGoal();
    var st = D.steps();
    var real = st >= goal ? len - 1 : (st * (len - 1)) / goal;
    var idx = awake && walk < real ? walk : real;
    var reached = st >= goal && idx == len - 1;
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 32, 36, G.L, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    G.t(dc, F.time, F.time_b, 30, 64, G.L, n.hhmm());
    dc.fillRectangle(25, 72, 126, 76);
    G.paper(dc);
    dc.fillRectangle(26, 73, 124, 74);
    G.ink(dc);
    for (var r = 0; r < 9; r++) {
      var ch = BASE[r].toCharArray();
      for (var i = 0; i < idx; i++) {
        if (PY[i] == r && ch[PX[i]] == '.') {
          ch[PX[i]] = ':';
        }
      }
      if (PY[idx] == r) {
        ch[PX[idx]] = '@';
      }
      G.t(dc, F.map, F.map_b, 26, 80 + r * 8, G.L, StringUtil.charArrayToString(ch));
    }
    var gk = goal >= 1000 ? (goal / 1000) + "K" : goal.toString();
    G.t(dc, F.lab, F.lab_b, 88, 161, G.C, reached ? "LEVEL UP!" : "STEPS " + st + "/" + gk);
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 15, G.C, "GOAL");
    var ang = 0.0;
    if (!reached) {
      ang = Math.atan2(2 - PY[idx], 21 - PX[idx]) * 180.0 / Math.PI + 90.0;
    }
    G.hand(dc, [[144, 24], [138, 41], [144, 37], [150, 41]] as Array<Array<Numeric>>, 144, 33, ang);
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, reached ? "HERE" : (len - 1 - idx).toString());
  }
}
