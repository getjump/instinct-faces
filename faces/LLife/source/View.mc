import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

class FaceView extends BaseFace {
  hidden const N = 44;
  hidden const M = 0x3FFFFF;
  hidden var lo as Array<Number>;
  hidden var hi as Array<Number>;
  hidden var gen as Number = 0;
  hidden var pop as Number = 0;
  hidden var lastMin as Number = -1;

  function initialize() {
    BaseFace.initialize();
    animMs = 400;
    lo = new [N] as Array<Number>;
    hi = new [N] as Array<Number>;
    for (var i = 0; i < N; i++) {
      lo[i] = 0;
      hi[i] = 0;
    }
    Math.srand(new Now().epoch);
    seed(30);
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  hidden function seed(p as Number) as Void {
    for (var y = 0; y < N; y++) {
      var a = 0;
      var b = 0;
      for (var x = 0; x < 22; x++) {
        if (Math.rand() % 100 < p) { a |= 1 << x; }
        if (Math.rand() % 100 < p) { b |= 1 << x; }
      }
      lo[y] |= a;
      hi[y] |= b;
    }
  }

  hidden function glider(x as Number, y as Number) as Void {
    var pts = [[1, 0], [2, 1], [0, 2], [1, 2], [2, 2]];
    for (var k = 0; k < pts.size(); k++) {
      var gx = (x + pts[k][0]) % N;
      var gy = (y + pts[k][1]) % N;
      if (gx < 22) {
        lo[gy] |= 1 << gx;
      } else {
        hi[gy] |= 1 << (gx - 22);
      }
    }
  }

  hidden function nextWord(u as Array<Number>, c as Array<Number>, d as Array<Number>, alive as Number) as Number {
    var s0 = 0;
    var s1 = 0;
    var s2 = 0;
    for (var i = 0; i < 8; i++) {
      var v = i < 3 ? u[i] : (i < 5 ? c[i - 3] : d[i - 5]);
      var c0 = s0 & v;
      s0 ^= v;
      var c1 = s1 & c0;
      s1 ^= c0;
      s2 |= c1;
    }
    return ~s2 & s1 & (s0 | alive) & M;
  }

  function step() as Void {
    var nl = new [N] as Array<Number>;
    var nh = new [N] as Array<Number>;
    var p = 0;
    for (var y = 0; y < N; y++) {
      var ym = (y + N - 1) % N;
      var yp = (y + 1) % N;
      var r0 = neighbours(ym);
      var r1 = neighbours(y);
      var r2 = neighbours(yp);
      var a = nextWord([r0[0], r0[2], lo[ym]] as Array<Number>, [r1[0], r1[2]] as Array<Number>, [r2[0], r2[2], lo[yp]] as Array<Number>, lo[y]);
      var b = nextWord([r0[1], r0[3], hi[ym]] as Array<Number>, [r1[1], r1[3]] as Array<Number>, [r2[1], r2[3], hi[yp]] as Array<Number>, hi[y]);
      nl[y] = a;
      nh[y] = b;
      p += bits(a) + bits(b);
    }
    lo = nl;
    hi = nh;
    gen++;
    pop = p;
    if (gen % 25 == 0) {
      glider(Math.rand() % N, Math.rand() % N);
    }
    if (pop < 90 || gen % 240 == 0) {
      seed(14);
    }
  }

  hidden function neighbours(y as Number) as [Number, Number, Number, Number] {
    var a = lo[y];
    var b = hi[y];
    return [((a << 1) & M) | (b >> 21), ((b << 1) & M) | (a >> 21), (a >> 1) | ((b & 1) << 21), (b >> 1) | ((a & 1) << 21)];
  }

  hidden function bits(v as Number) as Number {
    v = v - ((v >> 1) & 0x55555555);
    v = (v & 0x33333333) + ((v >> 2) & 0x33333333);
    return (((v + (v >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24 & 0xFF;
  }

  function render(dc as Dc, n as Now) as Void {
    if (n.m != lastMin) {
      lastMin = n.m;
      if (!awake) {
        step();
      }
      seed(14);
    }
    G.ink(dc);
    for (var y = 0; y < N; y++) {
      if (y >= 15 && y <= 27) {
        continue;
      }
      drawRow(dc, y, lo[y], 0);
      drawRow(dc, y, hi[y], 22);
    }
    dc.fillRectangle(0, 64, 176, 44);
    G.paper(dc);
    G.t(dc, F.time, F.time_b, 88, 101, G.C, n.hhmm());
    dc.fillRectangle(62, 150, 52, 12);
    G.ink(dc);
    dc.drawRectangle(62, 150, 52, 12);
    G.t(dc, F.lab, F.lab_b, 88, 159, G.C, U.dowU(n) + " " + U.p2(n.d));
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "GEN");
    G.t(dc, F.gen, F.gen_b, 144, 42, G.C, (gen % 100000).toString());
    G.t(dc, F.lab, F.lab_b, 144, 55, G.C, "P " + pop);
  }

  hidden function drawRow(dc as Dc, y as Number, w as Number, ox as Number) as Void {
    var x = ox;
    while (w != 0) {
      if ((w & 1) != 0) {
        dc.fillRectangle(x * 4, y * 4, 3, 3);
      }
      w >>= 1;
      x++;
    }
  }
}
