import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

class FaceView extends BaseFace {
  hidden const NAMES = ["1 ZAG", "2 BEG", "3 EVN", "4 TBS", "5 TAS *"] as Array<String>;
  hidden const BASE = [3, 11, 38, 14, 62] as Array<Number>;
  hidden const ROWY = [110, 121, 132, 143, 154] as Array<Number>;
  hidden var rtts as Array<String>;
  hidden var t0 as Number = 0;
  hidden var cyc as Number = 0;
  hidden var ping as Number = 62;

  function initialize() {
    BaseFace.initialize();
    animMs = 350;
    Math.srand(System.getTimer() + new Now().epoch);
    t0 = System.getTimer();
    rtts = new [5] as Array<String>;
    roll();
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function onExitSleep() as Void {
    t0 = System.getTimer();
    cyc = 0;
    roll();
    BaseFace.onExitSleep();
  }

  hidden function roll() as Void {
    for (var i = 0; i < 5; i++) {
      var v = BASE[i] * 10 + Math.rand() % 80;
      rtts[i] = (v / 10) + "." + (v % 10) + "ms";
    }
  }

  function render(dc as Dc, n as Now) as Void {
    var k = 5;
    var blink = false;
    if (awake) {
      var e = System.getTimer() - t0;
      var c = e / 7000;
      if (c != cyc) {
        cyc = c;
        roll();
      }
      k = (e % 7000) / 700;
      k = k > 5 ? 5 : k;
      blink = (e / 500) % 2 == 0;
      ping = 60 + (10 * Math.sin(System.getTimer() / 333.0)).toNumber() + Math.rand() % 4;
    }
    G.ink(dc);
    G.t(dc, F.txt, F.txt_b, 36, 36, G.L, U.dowL(n) + " " + U.p2(n.d) + " " + U.monU(n).toLower());
    G.t(dc, F.time, F.time_b, 18, 80, G.L, n.hhmm());
    G.t(dc, F.txt, F.txt_b, 20, 97, G.L, "$ traceroute home");
    for (var i = 0; i < 5; i++) {
      if (i < k) {
        G.t(dc, F.txt, F.txt_b, 32, ROWY[i], G.L, NAMES[i]);
        G.t(dc, F.txt, F.txt_b, 124, ROWY[i], G.R, rtts[i]);
      }
    }
    if (k < 5 && blink) {
      dc.fillRectangle(32, ROWY[k] - 8, 5, 9);
    }
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "RTT");
    G.t(dc, F.png, F.png_b, 144, 44, G.C, ping.toString());
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "MS");
  }
}
