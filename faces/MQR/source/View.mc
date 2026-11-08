import Toybox.Graphics;
import Toybox.Lang;

class FaceView extends BaseFace {
  hidden const GEN = [216, 194, 159, 111, 199, 94, 95, 113, 157, 193] as Array<Number>;
  hidden const FMT = 0x77C4;
  hidden const FULL = 0x1FFFFFF;
  hidden var mods as Array<Number>;
  hidden var fnm as Array<Number>;
  hidden var idx as Array<Number>;
  hidden var ex as Array<Number>;
  hidden var lg as Array<Number>;
  hidden var lastMin as Number = -1;
  hidden var payload as String = "";

  function initialize() {
    BaseFace.initialize();
    partialBox = [113, 0, 62, 62];
    mods = new [25] as Array<Number>;
    fnm = new [25] as Array<Number>;
    idx = new [37] as Array<Number>;
    for (var k = 0; k < 37; k++) {
      idx[k] = 0;
    }
    for (var k = 0; k <= 25; k++) {
      idx[(1 << k) % 37] = k;
    }
    for (var i = 0; i < 25; i++) {
      mods[i] = 0;
      fnm[i] = 0;
    }
    ex = new [255] as Array<Number>;
    lg = new [256] as Array<Number>;
    var v = 1;
    for (var i = 0; i < 255; i++) {
      ex[i] = v;
      lg[v] = i;
      v <<= 1;
      if (v > 255) {
        v ^= 0x11D;
      }
    }
    lg[0] = 0;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  hidden function setF(x as Number, y as Number, dark as Boolean) as Void {
    var b = 1 << x;
    fnm[y] |= b;
    if (dark) {
      mods[y] |= b;
    } else {
      mods[y] &= ~b;
    }
  }

  hidden function finder(cx as Number, cy as Number) as Void {
    for (var dy = -4; dy <= 4; dy++) {
      for (var dx = -4; dx <= 4; dx++) {
        var x = cx + dx;
        var y = cy + dy;
        if (x < 0 || y < 0 || x >= 25 || y >= 25) {
          continue;
        }
        var ax = dx < 0 ? -dx : dx;
        var ay = dy < 0 ? -dy : dy;
        var dist = ax > ay ? ax : ay;
        setF(x, y, dist != 2 && dist != 4);
      }
    }
  }

  hidden function gb(i as Number) as Boolean {
    return ((FMT >> i) & 1) != 0;
  }

  hidden function encode(text as String) as Void {
    for (var i = 0; i < 25; i++) {
      mods[i] = 0;
      fnm[i] = 0;
    }
    for (var i = 0; i < 25; i++) {
      setF(6, i, i % 2 == 0);
      setF(i, 6, i % 2 == 0);
    }
    finder(3, 3);
    finder(21, 3);
    finder(3, 21);
    for (var dy = -2; dy <= 2; dy++) {
      for (var dx = -2; dx <= 2; dx++) {
        var ax = dx < 0 ? -dx : dx;
        var ay = dy < 0 ? -dy : dy;
        setF(18 + dx, 18 + dy, (ax > ay ? ax : ay) != 1);
      }
    }
    for (var i = 0; i <= 5; i++) {
      setF(8, i, gb(i));
    }
    setF(8, 7, gb(6));
    setF(8, 8, gb(7));
    setF(7, 8, gb(8));
    for (var i = 9; i < 15; i++) {
      setF(14 - i, 8, gb(i));
    }
    for (var i = 0; i < 8; i++) {
      setF(24 - i, 8, gb(i));
    }
    for (var i = 8; i < 15; i++) {
      setF(8, 10 + i, gb(i));
    }
    setF(8, 17, true);

    var chars = text.toCharArray();
    var n = chars.size();
    var all = new [44] as Array<Number>;
    for (var i = 0; i < 44; i++) {
      all[i] = 0;
    }
    var bitPos = 0;
    var vals = [4, n] as Array<Number>;
    var lens = [4, 8] as Array<Number>;
    for (var k = 0; k < 2 + n; k++) {
      var v = k < 2 ? vals[k] : chars[k - 2].toNumber() & 255;
      var l = k < 2 ? lens[k] : 8;
      for (var i = l - 1; i >= 0; i--) {
        if (((v >> i) & 1) != 0) {
          all[bitPos >> 3] |= 128 >> (bitPos & 7);
        }
        bitPos++;
      }
    }
    var cap = 272;
    var term = cap - bitPos;
    bitPos += term > 4 ? 4 : term;
    bitPos = (bitPos + 7) & ~7;
    var pad = 0xEC;
    for (var p = bitPos >> 3; p < 34; p++) {
      all[p] = pad;
      pad ^= 0xEC ^ 0x11;
    }
    var ecc = new [10] as Array<Number>;
    for (var i = 0; i < 10; i++) {
      ecc[i] = 0;
    }
    for (var k = 0; k < 34; k++) {
      var factor = all[k] ^ ecc[0];
      for (var i = 0; i < 9; i++) {
        ecc[i] = ecc[i + 1];
      }
      ecc[9] = 0;
      for (var i = 0; i < 10; i++) {
        if (factor != 0) {
          ecc[i] ^= ex[(lg[GEN[i]] + lg[factor]) % 255];
        }
      }
    }
    for (var i = 0; i < 10; i++) {
      all[34 + i] = ecc[i];
    }
    var bi = 0;
    var right = 24;
    while (right >= 1) {
      if (right == 6) {
        right = 5;
      }
      var upward = ((right + 1) & 2) == 0;
      for (var vert = 0; vert < 25; vert++) {
        for (var j = 0; j < 2; j++) {
          var x = right - j;
          var y = upward ? 24 - vert : vert;
          if (((fnm[y] >> x) & 1) == 0 && bi < 352) {
            if (((all[bi >> 3] >> (7 - (bi & 7))) & 1) != 0) {
              mods[y] |= 1 << x;
            }
            bi++;
          }
        }
      }
      right -= 2;
    }
    for (var y = 0; y < 25; y++) {
      var m = (y % 2 == 0 ? 0x1555555 : 0x0AAAAAA) & ~fnm[y] & FULL;
      mods[y] ^= m;
    }
  }

  function render(dc as Dc, n as Now) as Void {
    if (n.m != lastMin) {
      lastMin = n.m;
      payload = "TIME " + n.hhmm() + " " + U.p2(n.d) + "." + U.p2(n.mon) + "." + U.p2(n.y % 100);
      encode(payload);
    }
    G.ink(dc);
    dc.fillRectangle(21, 43, 2, 12);
    dc.fillRectangle(21, 43, 12, 2);
    dc.fillRectangle(103, 43, 11, 2);
    dc.fillRectangle(112, 43, 2, 12);
    dc.fillRectangle(112, 125, 2, 11);
    dc.fillRectangle(103, 134, 11, 2);
    dc.fillRectangle(21, 134, 12, 2);
    dc.fillRectangle(21, 125, 2, 11);
    for (var y = 0; y < 25; y++) {
      var v = mods[y];
      while (v != 0) {
        var low = v & -v;
        var t = v + low;
        var e = t & -t;
        var s = idx[low % 37];
        dc.fillRectangle(30 + s * 3, 52 + y * 3, (idx[e % 37] - s) * 3, 3);
        v = v & t;
      }
    }
    G.t(dc, F.time, F.time_b, 116, 100, G.L, n.hhmm());
    G.t(dc, F.lab, F.lab_b, 116, 112, G.L, U.p2(n.d) + "." + U.p2(n.mon));
    G.t(dc, F.lab, F.lab_b, 116, 124, G.L, "SCAN");
    dc.drawRectangle(24, 140, 87, 5);
    if (awake) {
      dc.fillRectangle(25, 141, (85 * n.s / 59.0 + 0.5).toNumber(), 3);
    }
    G.t(dc, F.pay, F.pay_b, 88, 158, G.C, payload);
    sub(dc, n);
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    sub(dc, n);
  }

  hidden function sub(dc as Dc, n as Now) as Void {
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "SEC");
    G.t(dc, F.sec, F.sec_b, 144, 44, G.C, secLive() ? U.p2(n.s) : "--");
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, "V2-L");
  }
}
