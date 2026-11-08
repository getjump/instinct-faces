import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var img as BitmapResource or Null = null;
  hidden var imgK as Number = -1;
  hidden const IDS = [Rez.Drawables.s0, Rez.Drawables.s1, Rez.Drawables.s2, Rez.Drawables.s3, Rez.Drawables.s4, Rez.Drawables.s5, Rez.Drawables.s6, Rez.Drawables.s7, Rez.Drawables.s8, Rez.Drawables.s9, Rez.Drawables.s10, Rez.Drawables.s11, Rez.Drawables.s12, Rez.Drawables.s13, Rez.Drawables.s14, Rez.Drawables.s15, Rez.Drawables.s16, Rez.Drawables.s17, Rez.Drawables.s18, Rez.Drawables.s19, Rez.Drawables.s20, Rez.Drawables.s21, Rez.Drawables.s22, Rez.Drawables.s23];
  hidden const BA = [40, 130, 220, 300];
  hidden const BR = [30, 44, 20, 48];

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  hidden function px(a as Number, r as Numeric) as Float {
    return (82 + r * Math.sin(Math.toRadians(a))).toFloat();
  }

  hidden function py(a as Number, r as Numeric) as Float {
    return (102 - r * Math.cos(Math.toRadians(a))).toFloat();
  }

  function render(dc as Dc, n as Now) as Void {
    var k = awake ? (System.getTimer() / 250) % 24 : (n.m * 5) % 24;
    var a = k * 15;
    if (k != imgK) {
      img = null;
      img = WatchUi.loadResource(IDS[k]) as BitmapResource;
      imgK = k;
    }
    G.ink(dc);
    G.t(dc, F.time, F.time_b, 32, 42, G.L, n.hhmm());
    dc.drawBitmap(26, 46, img as BitmapResource);
    G.paper(dc);
    dc.setPenWidth(2);
    dc.drawLine(82, 102, px(a, 55), py(a, 55));
    dc.setPenWidth(1);
    var dt0 = 0;
    var dt1 = 0;
    for (var i = 0; i < 4; i++) {
      var dt = ((a - BA[i]) % 360 + 360) % 360;
      if (i == 0) {
        dt0 = dt;
      } else if (i == 1) {
        dt1 = dt;
      }
      var sz = 0;
      if (dt < 30) {
        sz = 4;
      } else if (dt < 90) {
        sz = 3;
      } else if (dt < 180) {
        sz = 2;
      } else if (dt < 260) {
        sz = 1;
      }
      if (sz > 0) {
        dc.fillRectangle(px(BA[i], BR[i]) - sz / 2.0, py(BA[i], BR[i]) - sz / 2.0, sz, sz);
      }
    }
    if (dt0 < 120) {
      G.t(dc, F.lab, F.lab_b, 106, 78, G.L, "MSG");
    }
    if (dt1 < 120) {
      G.t(dc, F.lab, F.lab_b, 111, 140, G.R, "15:00");
    }
    G.ink(dc);
    var nc = System.getDeviceSettings().notificationCount;
    G.t(dc, F.lab, F.lab_b, 140, 98, G.L, (nc == null ? 0 : nc) + " MSG");
    G.t(dc, F.lab, F.lab_b, 140, 110, G.L, "1 CAL");
    G.t(dc, F.lab, F.lab_b, 88, 168, G.C, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "SCAN");
    G.t(dc, F.brg, F.brg_b, 144, 44, G.C, (a < 100 ? "0" : "") + (a < 10 ? "0" : "") + a);
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "DEG");
  }
}
