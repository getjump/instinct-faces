import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden const DAYK = ["日", "月", "火", "水", "木", "金", "土"] as Array<String>;
  hidden var disc as BitmapResource or Null;
  hidden var lastKey as Number = -1;
  hidden var wipeAt as Number = -100;

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
    partialBox = [113, 0, 62, 62];
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    disc = WatchUi.loadResource(Rez.Drawables.disc) as BitmapResource;
  }

  function render(dc as Dc, n as Now) as Void {
    var key = n.h * 60 + n.m;
    if (key != lastKey) {
      lastKey = key;
      wipeAt = frame;
    }
    var cx = 96;
    var cy = 82;
    if (awake) {
      var a = frame * 0.2;
      cx = (96 + 4 * Math.cos(a)).toNumber();
      cy = (82 + 4 * Math.sin(a)).toNumber();
    }
    dc.drawBitmap(cx - 28, cy - 28, disc as BitmapResource);
    G.ink(dc);
    G.t(dc, F.s8, F.s8_b, 30, 38, G.L, "TIME 時刻");
    dc.setPenWidth(1);
    dc.drawLine(18, 94, 150, 94);
    dc.drawLine(128, 56, 128, 160);
    G.t(dc, F.big, F.big_b, 24, 86, G.L, U.p2(n.h));
    G.t(dc, F.k14, F.k14_b, 92, 86, G.L, "時");
    var wh = 60;
    if (awake) {
      wh = (frame - wipeAt) * 30;
      if (wh > 60) {
        wh = 60;
      }
    }
    if (wh > 0) {
      dc.setClip(0, 100, 176, wh);
      G.t(dc, F.big, F.big_b, 24, 146, G.L, U.p2(n.m));
      dc.clearClip();
    }
    G.t(dc, F.k14, F.k14_b, 92, 146, G.L, "分");
    var kata = ["タ", "シ", "ケ", "ン", "ト"];
    for (var i = 0; i < 5; i++) {
      G.t(dc, F.k12, F.k12_b, 142, 86 + i * 14, G.C, kata[i]);
    }
    G.t(dc, F.s8, F.s8_b, 88, 164, G.C, n.y + "." + U.p2(n.mon) + "." + U.p2(n.d) + " " + DAYK[n.dow]);
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    sub(dc, n);
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    sub(dc, n);
  }

  hidden function sub(dc as Dc, n as Now) as Void {
    G.t(dc, F.ss, F.ss_b, 144, 42, G.C, secLive() ? U.p2(n.s) : "--");
    G.t(dc, F.s8, F.s8_b, 144, 56, G.C, "ビョウ");
  }
}
