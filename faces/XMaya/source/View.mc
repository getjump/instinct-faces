import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var frameBmp as BitmapResource or Null;

  function initialize() {
    BaseFace.initialize();
    partialBox = [113, 0, 62, 62];
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    frameBmp = WatchUi.loadResource(Rez.Drawables.frame) as BitmapResource;
  }

  hidden function rd(v as Float) as Number {
    return (v + 0.5).toNumber();
  }

  hidden function glyph(dc as Dc, n as Number, bx as Float, by as Float, ox as Float, oy as Float, sc as Float) as Void {
    if (n == 0) {
      var cy = by + 20;
      dc.setPenWidth(sc < 1 ? 1 : 2);
      dc.drawEllipse(rd(ox + (bx + 15.5) * sc), rd(oy + cy * sc), rd(11 * sc), rd(6 * sc));
      dc.setPenWidth(1);
      var x0 = rd(ox + (bx + 9.5) * sc);
      var x1 = rd(ox + (bx + 15.5) * sc);
      var x2 = rd(ox + (bx + 21.5) * sc);
      dc.drawLine(x0, rd(oy + (cy - 1.5) * sc), x1, rd(oy + (cy + 0.25) * sc));
      dc.drawLine(x1, rd(oy + (cy + 0.25) * sc), x2, rd(oy + (cy - 1.5) * sc));
      return;
    }
    var bars = n / 5;
    var dots = n % 5;
    var bh = rd(4.5 * sc);
    for (var i = 0; i < bars; i++) {
      var y = by + 22.5 - i * 7;
      dc.fillRectangle(rd(ox + (bx + 2.5) * sc), rd(oy + y * sc), rd(26 * sc), bh);
    }
    if (dots > 0) {
      var cy = by + 23.5 - bars * 7;
      var sx = bx + 15.5 - (dots - 1) * 3.25;
      for (var i = 0; i < dots; i++) {
        dc.fillCircle(rd(ox + (sx + i * 6.5) * sc), rd(oy + cy * sc), rd(2.4 * sc));
      }
    }
  }

  hidden function number(dc as Dc, v as Number, bx as Float, uy as Float, ly as Float, ox as Float, oy as Float, sc as Float) as Void {
    if (v >= 20) {
      glyph(dc, v / 20, bx, uy, ox, oy, sc);
    }
    glyph(dc, v % 20, bx, ly, ox, oy, sc);
  }

  function render(dc as Dc, n as Now) as Void {
    dc.drawBitmap(22, 36, frameBmp as BitmapResource);
    G.ink(dc);
    number(dc, n.h, 28.0, 58.0, 94.0, 0.0, 0.0, 1.0);
    number(dc, n.m, 78.0, 58.0, 94.0, 0.0, 0.0, 1.0);
    G.t(dc, F.time, F.time_b, 88, 158, G.C, n.hhmm());
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    sub(dc, n);
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    sub(dc, n);
  }

  hidden function sub(dc as Dc, n as Now) as Void {
    if (secLive()) {
      number(dc, n.s, 0.0, 0.0, 36.0, 136.5, 10.0, 0.5);
    }
    G.t(dc, F.lab, F.lab_b, 144, 58, G.C, "SEC");
  }
}
