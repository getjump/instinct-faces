import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var dial as BitmapResource or Null;
  hidden var gb as BitmapResource or Null;
  hidden var gs as BitmapResource or Null;
  hidden var gm as BitmapResource or Null;
  hidden const BX = [22, 48, 84, 110];

  function initialize() {
    BaseFace.initialize();
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    dial = WatchUi.loadResource(Rez.Drawables.dial) as BitmapResource;
    gb = WatchUi.loadResource(Rez.Drawables.gb) as BitmapResource;
    gs = WatchUi.loadResource(Rez.Drawables.gs) as BitmapResource;
    gm = WatchUi.loadResource(Rez.Drawables.gm) as BitmapResource;
  }

  hidden function cell(dc as Dc, bmp as BitmapResource, k as Number, cw as Number, ch as Number, x as Number, y as Number) as Void {
    dc.setClip(x, y, cw, ch);
    dc.drawBitmap(x - k * cw, y, bmp);
    dc.clearClip();
  }

  function render(dc as Dc, n as Now) as Void {
    dc.drawBitmap(0, 0, dial as BitmapResource);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 52, 47, G.L, U.dowU(n));
    var d = [n.h / 10, n.h % 10, n.m / 10, n.m % 10];
    for (var i = 0; i < 4; i++) {
      cell(dc, gb as BitmapResource, d[i], 28, 48, BX[i] - 4, 72);
    }
    var live = awake;
    if (!live || n.s % 2 == 0) {
      dc.fillRectangle(74, 87, 4, 4);
      dc.fillRectangle(74, 103, 4, 4);
    }
    var a = live ? n.s / 10 : 10;
    var b = live ? n.s % 10 : 10;
    cell(dc, gs as BitmapResource, a, 14, 22, 137, 97);
    cell(dc, gs as BitmapResource, b, 14, 22, 149, 97);
    G.ink(dc);
    if (System.getDeviceSettings().alarmCount > 0) {
      dc.fillRectangle(36, 120, 4, 1);
      dc.fillRectangle(35, 121, 6, 5);
      dc.fillRectangle(34, 126, 8, 1);
      dc.fillRectangle(37, 128, 2, 1);
    }
    if (D.solar() > 0) {
      G.t(dc, F.lab, F.lab_b, 90, 128, G.L, "SOL");
    }
    if (live) {
      var lim = n.s / 2 + 1;
      for (var i = 0; i < lim; i++) {
        dc.fillRectangle((70 + 7 * i) / 2, 138, 3, 6);
      }
    }
    cell(dc, gm as BitmapResource, n.d / 10, 16, 26, 130, 19);
    cell(dc, gm as BitmapResource, n.d % 10, 16, 26, 146, 19);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, U.monU(n));
  }
}
