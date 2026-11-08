import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden const NUM = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"] as Array<String>;
  hidden const DAYK = ["日", "月", "火", "水", "木", "金", "土"] as Array<String>;
  hidden var revealAt as Number = 0;

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
    partialBox = [113, 0, 62, 62];
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function onExitSleep() as Void {
    revealAt = frame;
    BaseFace.onExitSleep();
  }

  hidden function kn(v as Number) as String {
    if (v < 10) {
      return NUM[v];
    }
    var t = v / 10;
    var o = v % 10;
    return (t == 1 ? "" : NUM[t]) + "十" + (o > 0 ? NUM[o] : "");
  }

  hidden function col(dc as Dc, f as FontResource or Null, b as Number, s as String, x as Number, y0 as Number, dy as Number, el as Number, e0 as Number) as Void {
    for (var i = 0; i < s.length() && i < 7; i++) {
      if (el >= e0 + i) {
        G.t(dc, f, b, x, y0 + i * dy, G.C, s.substring(i, i + 1) as String);
      }
    }
  }

  function render(dc as Dc, n as Now) as Void {
    var el = awake ? frame - revealAt : 99;
    G.ink(dc);
    dc.drawLine(73, 36, 73, 156);
    dc.drawLine(38, 44, 38, 150);
    col(dc, F.k26, F.k26_b, kn(n.h) + "時", 90, 62, 28, el, 0);
    col(dc, F.k26, F.k26_b, kn(n.m) + "分", 56, 62, 28, el, 4);
    col(dc, F.k11, F.k11_b, kn(n.mon) + "月" + kn(n.d) + "日", 25, 60, 13, 99, 0);
    if (el >= 10) {
      dc.fillRoundedRectangle(114, 114, 28, 28, 3);
      G.paper(dc);
      dc.drawRoundedRectangle(116, 116, 24, 24, 2);
      G.t(dc, F.k12, F.k12_b, 128, 127, G.C, DAYK[n.dow]);
      G.t(dc, F.k12, F.k12_b, 128, 139, G.C, "曜");
    }
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    sub(dc, n);
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    sub(dc, n);
  }

  hidden function sub(dc as Dc, n as Now) as Void {
    G.t(dc, F.sec, F.sec_b, 144, 42, G.C, secLive() ? U.p2(n.s) : "--");
    G.t(dc, F.k11, F.k11_b, 144, 57, G.C, "秒");
  }
}
