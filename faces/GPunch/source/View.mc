import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var card as BitmapResource or Null;
  hidden var pt as Array<Number>;
  hidden var inited as Boolean = false;
  hidden const COLX = [40, 54, 76, 90, 112, 126];
  hidden const ROWY = [84, 97, 110, 123];
  hidden const BITS = [8, 4, 2, 1];
  hidden const VALID = [[0, 0, 1, 1], [1, 1, 1, 1], [0, 1, 1, 1], [1, 1, 1, 1], [0, 1, 1, 1], [1, 1, 1, 1]];
  hidden const SB = [32, 16, 8, 4, 2, 1];

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
    partialBox = [113, 0, 62, 62];
    pt = new [24] as Array<Number>;
    for (var i = 0; i < 24; i++) {
      pt[i] = -1;
    }
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    card = WatchUi.loadResource(Rez.Drawables.card) as BitmapResource;
  }

  function render(dc as Dc, n as Now) as Void {
    var ms = System.getTimer();
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 30, 64, G.L, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    dc.drawBitmap(24, 44, card as BitmapResource);
    var digits = [n.h / 10, n.h % 10, n.m / 10, n.m % 10, n.s / 10, n.s % 10];
    var cols = awake ? 6 : 4;
    for (var c = 0; c < 6; c++) {
      for (var r = 0; r < 4; r++) {
        if (VALID[c][r] == 0) {
          continue;
        }
        var key = c * 4 + r;
        var on = c < cols && (digits[c] & BITS[r]) != 0;
        if (on) {
          if (pt[key] < 0) {
            pt[key] = inited ? ms : 0;
          }
          dc.fillRectangle(COLX[c], ROWY[r], 8, 9);
          if (awake) {
            var age = ms - pt[key];
            if (age < 600) {
              var fall = 10 + 120 * age * age / 1000000;
              dc.fillRectangle(COLX[c] + 2, ROWY[r] + fall, 4, 4);
            }
          }
        } else {
          pt[key] = -1;
        }
      }
    }
    inited = true;
    G.t(dc, F.hms, F.hms_b, 88, 162, G.C, n.hhmm() + ":" + (awake ? U.p2(n.s) : "--"));
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    sub(dc, n);
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    sub(dc, n);
  }

  hidden function sub(dc as Dc, n as Now) as Void {
    var live = secLive();
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "SEC");
    for (var i = 0; i < 6; i++) {
      var x = 126 + i * 6;
      if (live && (n.s & SB[i]) != 0) {
        dc.fillRectangle(x, 30, 5, 6);
      } else {
        dc.drawRectangle(x, 30, 5, 6);
      }
    }
    G.t(dc, F.lab, F.lab_b, 144, 52, G.C, live ? U.p2(n.s) : "--");
  }
}
