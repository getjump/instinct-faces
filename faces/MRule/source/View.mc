import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

class FaceView extends BaseFace {
  hidden const M = 0x3FFFFF;
  hidden var rows as Array<Number>;
  hidden var idx as Array<Number>;
  hidden var head as Number = 0;
  hidden var gen as Number = 87;
  hidden var lastMin as Number = -1;

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
    idx = new [37] as Array<Number>;
    for (var k = 0; k < 37; k++) {
      idx[k] = 0;
    }
    for (var k = 0; k <= 22; k++) {
      idx[(1 << k) % 37] = k;
    }
    rows = new [352] as Array<Number>;
    for (var i = 0; i < 352; i++) {
      rows[i] = 0;
    }
    rows[2] = 1;
    for (var r = 1; r < 88; r++) {
      calc(r - 1, r);
    }
    Math.srand(new Now().epoch);
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  hidden function calc(from as Number, to as Number) as Void {
    var f = from * 4;
    var t = to * 4;
    for (var w = 0; w < 4; w++) {
      var v = rows[f + w];
      var pw = rows[f + (w + 3) % 4];
      var nw = rows[f + (w + 1) % 4];
      var l = ((v << 1) & M) | (pw >> 21);
      var r = (v >> 1) | ((nw & 1) << 21);
      rows[t + w] = (l ^ (v | r)) & M;
    }
  }

  function step() as Void {
    var newest = (head + 87) % 88;
    calc(newest, head);
    head = (head + 1) % 88;
    gen++;
  }

  function render(dc as Dc, n as Now) as Void {
    if (n.m != lastMin) {
      if (lastMin >= 0) {
        if (!awake) {
          step();
        }
        var c = Math.rand() % 88;
        var base = ((head + 87) % 88) * 4 + c / 22;
        rows[base] = rows[base] ^ (1 << (c % 22));
      }
      lastMin = n.m;
    }
    G.ink(dc);
    for (var k = 0; k < 88; k++) {
      var b = ((head + k) % 88) * 4;
      var y = k * 2;
      for (var w = 0; w < 4; w++) {
        if ((w == 3 && k < 31) || ((w == 1 || w == 2) && k >= 36 && k <= 53)) {
          continue;
        }
        var v = rows[b + w];
        var ox = w * 44;
        while (v != 0) {
          var low = v & -v;
          var t = v + low;
          var e = t & -t;
          var s = idx[low % 37];
          dc.fillRectangle(ox + s * 2, y, (idx[e % 37] - s) * 2, 2);
          v = v & t;
        }
      }
    }
    dc.fillRectangle(40, 72, 97, 35);
    G.paper(dc);
    dc.fillRectangle(41, 73, 95, 33);
    G.ink(dc);
    G.t(dc, F.time, F.time_b, 88, 101, G.C, n.hhmm());
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "RULE");
    G.t(dc, F.rule, F.rule_b, 144, 44, G.C, "30");
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "G" + (gen % 100000));
  }
}
