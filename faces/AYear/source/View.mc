import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

class FaceView extends BaseFace {
  hidden var pos as Array<Number>;

  function initialize() {
    BaseFace.initialize();
    animMs = 400;
    var p = [] as Array<Number>;
    for (var y = 8; y <= 134; y += 6) {
      for (var x = 6; x <= 168; x += 6) {
        var ax = x + 2 - 88;
        var ay = y + 2 - 88;
        var bx = x + 2 - 144;
        var by = y + 2 - 32;
        if (ax * ax + ay * ay < 84 * 84 && bx * bx + by * by > 39 * 39) {
          p.add(x | (y << 8));
        }
      }
    }
    pos = p;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function render(dc as Dc, n as Now) as Void {
    var year = n.y;
    var total = ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) ? 366 : 365;
    var doy = n.doy();
    var cnt = total < pos.size() ? total : pos.size();
    G.ink(dc);
    for (var i = 0; i < cnt; i++) {
      var x = pos[i] & 0xFF;
      var y = pos[i] >> 8;
      if (i + 1 < doy) {
        dc.fillRectangle(x, y, 4, 4);
      } else if (i + 1 == doy) {
        if (!awake || frame % 2 == 0) {
          dc.fillRectangle(x, y, 4, 4);
        }
        dc.drawRectangle(x - 2, y - 2, 8, 8);
      } else {
        dc.fillRectangle(x + 2, y + 2, 1, 1);
      }
    }
    G.t(dc, F.time, F.time_b, 88, 160, G.C, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 88, 170, G.C, U.monU(n) + " " + U.p2(n.d) + " " + year);
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "DAY");
    G.t(dc, F.doy, F.doy_b, 144, 44, G.C, doy.toString());
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, (doy * 100 / total) + "%");
  }
}
