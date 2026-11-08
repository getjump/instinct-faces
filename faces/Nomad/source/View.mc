import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var base as BitmapResource or Null;

  function initialize() {
    BaseFace.initialize();
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    base = WatchUi.loadResource(Rez.Drawables.base) as BitmapResource;
  }

  function render(dc as Dc, n as Now) as Void {
    var ct = System.getClockTime();
    var off = ct.timeZoneOffset + ct.dst;
    var tyo = (n.epoch + 32400) % 86400;
    var utc = n.epoch % 86400;
    var diff = (32400 - off) / 3600;
    dc.drawBitmap(0, 0, base as BitmapResource);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 32, 36, G.L, "LOCAL");
    G.t(dc, F.lab, F.lab_b, 26, 50, G.L, "UTC" + zone(off));
    G.t(dc, F.time, F.time_b, 26, 103, G.L, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 88, 158, G.C, "UTC " + hm(utc));
    mark(dc, 106, n.h * 60 + n.m, 110);
    mark(dc, 124, (tyo / 60) % 1440, 124);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "TYO " + (diff >= 0 ? "+" : "") + diff);
    G.t(dc, F.sub, F.sub_b, 144, 42, G.C, hm(tyo));
    dc.fillCircle(144, 51, 4);
    G.paper(dc);
    dc.fillCircle(146, 49, 4);
  }

  hidden function mark(dc as Dc, dummy as Number, mins as Number, y as Number) as Void {
    var x = 42 + (mins * 107 / 1440).toNumber();
    G.paper(dc);
    dc.fillRectangle(x - 1, y, 3, 12);
    G.ink(dc);
    dc.fillRectangle(x, y, 1, 12);
  }

  hidden function hm(sec as Number) as String {
    return U.p2((sec / 3600) % 24) + ":" + U.p2((sec / 60) % 60);
  }

  hidden function zone(off as Number) as String {
    var a = off < 0 ? -off : off;
    var s = (off < 0 ? "-" : "+") + (a / 3600);
    if ((a / 60) % 60 != 0) {
      s += ":" + U.p2((a / 60) % 60);
    }
    return s;
  }
}
