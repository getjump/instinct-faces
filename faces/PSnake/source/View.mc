import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden const DX = [1, -1, 0, 0] as Array<Number>;
  hidden const DY = [0, 0, 1, -1] as Array<Number>;
  hidden var grid as BitmapResource or Null;
  hidden var sx as Array<Number>;
  hidden var sy as Array<Number>;
  hidden var occ as Array<Number>;
  hidden var head as Number = 0;
  hidden var len as Number = 0;
  hidden var base as Number = 3;
  hidden var dx as Number = 1;
  hidden var dy as Number = 0;
  hidden var ax as Number = 0;
  hidden var ay as Number = 0;
  hidden var eaten as Number = 0;
  hidden var lastMin as Number = -1;
  hidden var steps as Number = 0;

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
    sx = new [48] as Array<Number>;
    sy = new [48] as Array<Number>;
    occ = new [13] as Array<Number>;
    Math.srand(new Now().epoch);
    steps = D.steps();
    reset();
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    grid = WatchUi.loadResource(Rez.Drawables.grid) as BitmapResource;
  }

  hidden function reset() as Void {
    var s = steps / 1000;
    base = 3 + (s > 17 ? 17 : s);
    for (var r = 0; r < 13; r++) {
      occ[r] = 0;
    }
    head = 0;
    len = base;
    for (var i = 0; i < base; i++) {
      var c = (10 - i + 21) % 21;
      var idx = (head + base - 1 - i) % 48;
      sx[idx] = c;
      sy[idx] = 6;
      occ[6] |= 1 << c;
    }
    head = (head + base - 1) % 48;
    dx = 1;
    dy = 0;
    food();
  }

  hidden function food() as Void {
    for (var k = 0; k < 60; k++) {
      var c = Math.rand() % 21;
      var r = Math.rand() % 13;
      if (((occ[r] >> c) & 1) == 0) {
        ax = c;
        ay = r;
        return;
      }
    }
    ax = 0;
    ay = 0;
  }

  hidden function move() as Void {
    var hx = sx[head];
    var hy = sy[head];
    var tail = (head + 48 - len + 1) % 48;
    var best = -1;
    var bestD = 1000.0;
    for (var k = 0; k < 4; k++) {
      if (DX[k] == -dx && DY[k] == -dy) {
        continue;
      }
      var nx = (hx + DX[k] + 21) % 21;
      var ny = (hy + DY[k] + 13) % 13;
      if (((occ[ny] >> nx) & 1) != 0 && !(nx == sx[tail] && ny == sy[tail])) {
        continue;
      }
      var ddx = nx > ax ? nx - ax : ax - nx;
      ddx = ddx < 21 - ddx ? ddx : 21 - ddx;
      var ddy = ny > ay ? ny - ay : ay - ny;
      ddy = ddy < 13 - ddy ? ddy : 13 - ddy;
      var d = ddx + ddy + (Math.rand() % 30) / 100.0;
      if (d < bestD) {
        bestD = d;
        best = k;
      }
    }
    if (best < 0) {
      reset();
      return;
    }
    dx = DX[best];
    dy = DY[best];
    var nx = (hx + dx + 21) % 21;
    var ny = (hy + dy + 13) % 13;
    var ate = nx == ax && ny == ay;
    if (!ate) {
      occ[sy[tail]] &= ~(1 << sx[tail]);
      len--;
    }
    head = (head + 1) % 48;
    sx[head] = nx;
    sy[head] = ny;
    occ[ny] |= 1 << nx;
    len++;
    if (ate) {
      eaten++;
      if (len > 40) {
        var drop = len - base;
        for (var i = 0; i < drop; i++) {
          var t2 = (head + 48 - len + 1) % 48;
          occ[sy[t2]] &= ~(1 << sx[t2]);
          len--;
        }
      }
      food();
    }
  }

  function step() as Void {
    move();
    move();
  }

  function render(dc as Dc, n as Now) as Void {
    if (n.m != lastMin) {
      lastMin = n.m;
      steps = D.steps();
      if (!awake) {
        for (var i = 0; i < 8; i++) {
          move();
        }
      }
    }
    dc.drawBitmap(24, 68, grid as BitmapResource);
    G.ink(dc);
    G.t(dc, F.time, F.time_b, 28, 60, G.L, n.hhmm());
    var px = 26 + ax * 6;
    var py = 70 + ay * 6;
    dc.fillPolygon([[px + 2.5, py], [px + 5, py + 2.5], [px + 2.5, py + 5], [px, py + 2.5]] as Array<[Numeric, Numeric]>);
    for (var i = 0; i < len; i++) {
      var k = (head + 48 - i) % 48;
      dc.fillRectangle(26 + sx[k] * 6, 70 + sy[k] * 6, 5, 5);
    }
    G.paper(dc);
    var hx = 26 + sx[head] * 6;
    var hy = 70 + sy[head] * 6;
    dc.fillRectangle((hx + 2 + dx * 1.5 + 0.5).toNumber(), (hy + 2 + dy * 1.5 + 0.5).toNumber(), 1, 1);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 88, 162, G.C, "LEN " + len + " / " + (steps / 1000) + "." + ((steps % 1000) / 100) + "K");
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "APPLES");
    G.t(dc, F.num, F.num_b, 144, 44, G.C, eaten.toString());
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "TODAY");
  }
}
