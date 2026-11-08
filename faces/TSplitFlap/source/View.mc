import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var cur as Array<Number>;
  hidden var old as Array<Number>;
  hidden var fl as Array<Number>;
  hidden const TX = [18, 54, 94, 130];

  function initialize() {
    BaseFace.initialize();
    animMs = 200;
    partialBox = [113, 0, 62, 62];
    cur = [-1, -1, -1, -1, -1, -1];
    old = [0, 0, 0, 0, 0, 0];
    fl = [0, 0, 0, 0, 0, 0];
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function step() as Void {
    for (var i = 0; i < 6; i++) {
      if (fl[i] > 0) {
        fl[i]--;
      }
    }
  }

  hidden function tile(dc as Dc, x as Number, y as Number, w as Number, h as Number, r as Number, f as FontResource, fb as Number, ty as Number, top as Number, bot as Number) as Void {
    G.ink(dc);
    dc.fillRoundedRectangle(x, y, w, h, r);
    G.paper(dc);
    var cx = x + w / 2;
    if (top == bot) {
      G.t(dc, f, fb, cx, ty, G.C, top < 0 ? "-" : top.toString());
    } else {
      dc.setClip(x, y, w, h / 2);
      G.t(dc, f, fb, cx, ty, G.C, top.toString());
      dc.setClip(x, y + h / 2, w, h / 2);
      G.t(dc, f, fb, cx, ty, G.C, bot.toString());
      dc.clearClip();
    }
    dc.fillRectangle(x, y + h / 2 - 1, w, 1);
    G.ink(dc);
  }

  hidden function digits(n as Now) as Array<Number> {
    return [n.h / 10, n.h % 10, n.m / 10, n.m % 10, n.s / 10, n.s % 10];
  }

  hidden function hm(e as Number) as String {
    var i = Time.Gregorian.info(new Time.Moment(e), Time.FORMAT_SHORT);
    return U.p2(i.hour) + ":" + U.p2(i.min);
  }

  function render(dc as Dc, n as Now) as Void {
    var d = digits(n);
    for (var i = 0; i < 6; i++) {
      if (!awake || cur[i] < 0) {
        cur[i] = d[i];
        fl[i] = 0;
      } else if (d[i] != cur[i]) {
        old[i] = cur[i];
        cur[i] = d[i];
        fl[i] = 2;
      }
    }
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 26, 50, G.L, U.dowU(n) + " " + U.p2(n.d) + " " + U.monU(n));
    for (var i = 0; i < 4; i++) {
      tile(dc, TX[i], 70, 32, 48, 3, F.big, F.big_b, 110, cur[i], fl[i] > 0 ? old[i] : cur[i]);
    }
    if (!awake || n.s % 2 == 0) {
      dc.fillRectangle(89, 84, 3, 3);
      dc.fillRectangle(89, 101, 3, 3);
    }
    var st = D.sunTimes();
    G.t(dc, F.lab, F.lab_b, 30, 140, G.L, (st == null ? "--:--" : hm(st[0])) + " SUNRISE");
    G.t(dc, F.lab, F.lab_b, 30, 152, G.L, (st == null ? "--:--" : hm(st[1])) + " SUNSET");
    for (var i = 4; i < 6; i++) {
      tile(dc, 125 + (i - 4) * 20, 20, 18, 28, 2, F.sm, F.sm_b, 43, cur[i], fl[i] > 0 ? old[i] : cur[i]);
    }
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 58, G.C, "SEC");
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    var live = secLive();
    var a = live ? n.s / 10 : -1;
    var b = live ? n.s % 10 : -1;
    tile(dc, 125, 20, 18, 28, 2, F.sm, F.sm_b, 43, a, a);
    tile(dc, 145, 20, 18, 28, 2, F.sm, F.sm_b, 43, b, b);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 58, G.C, "SEC");
  }
}
