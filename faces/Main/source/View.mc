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
    G.t(dc, F.txt, F.txt_b, 36, 32, G.L, "~$ now");
    G.t(dc, F.txt, F.txt_b, 24, 47, G.L, U.dowL(n) + " " + U.p2(n.d) + " " + U.monU(n).toLower());
    G.t(dc, F.big, F.big_b, 20, 104, G.L, n.hhmm());
    G.t(dc, F.txt, F.txt_b, 22, 118, G.L, "~$ vitals");
    G.t(dc, F.txt, F.txt_b, 22, 131, G.L, "hr " + D.hr() + " | steps " + D.steps());
    var seg = (D.batt() + 5) / 10;
    for (var i = 0; i < 10; i++) {
      var x = 26 + i * 8;
      if (i < seg) {
        dc.fillRectangle(x, 138, 6, 7);
      } else {
        dc.drawRectangle(x, 138, 6, 7);
      }
    }
    G.t(dc, F.txt, F.txt_b, 110, 145, G.L, D.battDays() + "d");
    G.t(dc, F.txt, F.txt_b, 50, 163, G.L, "~$");
    dc.fillRectangle(66, 153, 7, 11);
    sub(dc, n);
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    sub(dc, n);
  }

  hidden function sub(dc as Dc, n as Now) as Void {
    G.t(dc, F.lab, F.lab_b, 144, 22, G.C, "sec");
    G.t(dc, F.num, F.num_b, 144, 50, G.C, secLive() ? U.p2(n.s) : "--");
  }
}
