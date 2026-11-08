import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var back as BitmapResource or Null;
  hidden const LET = ["S", "M", "T", "W", "T", "F", "S"] as Array<String>;

  function initialize() {
    BaseFace.initialize();
    animMs = 600;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    back = WatchUi.loadResource(Rez.Drawables.back) as BitmapResource;
  }

  function render(dc as Dc, n as Now) as Void {
    dc.drawBitmap(0, 0, back as BitmapResource);
    G.ink(dc);
    G.t(dc, F.time, F.time_b, 26, 52, G.L, n.hhmm());
    var hist = D.stepHistory();
    var today = D.steps();
    var steps = new [7] as Array<Number>;
    for (var i = 0; i < 7; i++) {
      var ago = 6 - i;
      steps[i] = ago == 0 ? today : (ago <= hist.size() ? hist[ago - 1] : 0);
    }
    var seed = awake ? frame : 0;
    var topX = 0;
    var topY = 140;
    for (var i = 0; i < 7; i++) {
      var x = 18 + i * 20;
      var h = steps[i] * 70 / 13000;
      h = h < 2 ? 2 : (h > 70 ? 70 : h);
      var y = 140 - h;
      G.ink(dc);
      dc.fillRectangle(x, y, 16, h);
      if (h > 6) {
        G.paper(dc);
        var top = y + 3;
        for (var b = 1; 141 - 6 * b < 139; b++) {
          var wy = 141 - 6 * b;
          if (wy + 3 <= top) {
            break;
          }
          var cy = wy < top ? top : wy;
          for (var c = 0; c < 3; c++) {
            dc.fillRectangle(x + 5 * c + 1, cy, 2, wy + 3 - cy);
          }
        }
      }
      G.ink(dc);
      if (steps[i] >= 10000) {
        dc.fillRectangle(x + 8, y - 9, 1, 9);
        dc.fillPolygon([[x + 9, y - 9], [x + 14, y - 7], [x + 9, y - 5]] as Array<[Numeric, Numeric]>);
      }
      if (awake && h > 10) {
        var rows = (h - 4) / 6;
        rows = rows < 1 ? 1 : rows;
        for (var j = 0; j < 2; j++) {
          var hs = ((seed * 7 + i * 13 + j * 31) * 40503 + 12345) & 0x7FFFFFFF;
          var col = (hs >> 3) % 3;
          var row = (hs >> 9) % rows;
          dc.fillRectangle(x + 1 + col * 5, 135 - 6 * row, 2, 3);
        }
      }
      if (i == 6) {
        topX = x + 7;
        topY = y - 3;
      }
    }
    if (!awake || frame % 2 == 0) {
      dc.fillRectangle(topX, topY, 2, 2);
    }
    for (var i = 0; i < 7; i++) {
      G.t(dc, F.lab, F.lab_b, 26 + i * 20, 151, G.C, LET[(n.dow - 6 + i + 7) % 7]);
    }
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "TODAY");
    G.t(dc, F.st, F.st_b, 144, 44, G.C, today.toString());
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, (today * 100 / 10000) + "%");
  }
}
