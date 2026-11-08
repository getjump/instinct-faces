import Toybox.Graphics;
import Toybox.Lang;

class FaceView extends BaseFace {
  function initialize() {
    BaseFace.initialize();
    partialBox = [113, 0, 62, 62];
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function render(dc as Dc, n as Now) as Void {
    G.ink(dc);
    dc.fillRectangle(0, 0, 176, 90);
    G.paper(dc);
    G.t(dc, F.hh, F.hh_b, 26, 84, G.L, U.p2(n.h));
    G.t(dc, F.bold, F.bold_b, 114, 77, G.L, U.dowU(n));
    G.t(dc, F.bold, F.bold_b, 114, 87, G.L, U.p2(n.d) + "." + U.p2(n.mon));
    G.ink(dc);
    G.t(dc, F.mm, F.mm_b, 54, 157, G.L, U.p2(n.m));
    heart(dc);
    sun(dc);
    var hr = D.hr();
    G.t(dc, F.lab, F.lab_b, 26, 122, G.L, hr > 0 ? hr.toString() : "--");
    var bd = D.battDays();
    G.t(dc, F.lab, F.lab_b, 26, 145, G.L, bd > 0 ? bd + "D" : "--");
    sub(dc, n);
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    sub(dc, n);
  }

  hidden function sub(dc as Dc, n as Now) as Void {
    G.paper(dc);
    dc.fillRectangle(113, 0, 62, 62);
    G.ink(dc);
    G.t(dc, F.sec, F.sec_b, 144, 45, G.C, secLive() ? U.p2(n.s) : "--");
    G.t(dc, F.lab, F.lab_b, 144, 57, G.C, "SEC");
  }

  hidden function heart(dc as Dc) as Void {
    dc.fillRectangle(27, 106, 2, 1);
    dc.fillRectangle(30, 106, 2, 1);
    dc.fillRectangle(26, 107, 7, 2);
    dc.fillRectangle(27, 109, 5, 1);
    dc.fillRectangle(28, 110, 3, 1);
    dc.fillRectangle(29, 111, 1, 1);
  }

  hidden function sun(dc as Dc) as Void {
    dc.fillRectangle(28, 130, 3, 3);
    dc.fillRectangle(29, 128, 1, 1);
    dc.fillRectangle(29, 134, 1, 1);
    dc.fillRectangle(26, 131, 1, 1);
    dc.fillRectangle(32, 131, 1, 1);
    dc.fillRectangle(27, 129, 1, 1);
    dc.fillRectangle(31, 129, 1, 1);
    dc.fillRectangle(27, 133, 1, 1);
    dc.fillRectangle(31, 133, 1, 1);
  }
}
