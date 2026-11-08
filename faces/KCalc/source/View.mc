import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden var dial as BitmapResource or Null;
  hidden var g7 as BitmapResource or Null;
  hidden var ph as Number = 0;
  hidden var seq as Number = 0;
  hidden const KEYS = ["7", "8", "9", "/", "4", "5", "6", "X", "1", "2", "3", "-", "0", ".", "=", "+"];

  function initialize() {
    BaseFace.initialize();
    animMs = 330;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    dial = WatchUi.loadResource(Rez.Drawables.dial) as BitmapResource;
    g7 = WatchUi.loadResource(Rez.Drawables.g7) as BitmapResource;
  }

  function onExitSleep() as Void {
    ph = 0;
    seq = (seq + 1) % 3;
    BaseFace.onExitSleep();
  }

  function step() as Void {
    if (ph < 40) {
      ph++;
    }
  }

  hidden function cell(dc as Dc, k as Number, x as Number) as Void {
    dc.setClip(x, 49, 14, 24);
    dc.drawBitmap(x - k * 14, 49, g7 as BitmapResource);
    dc.clearClip();
  }

  hidden function demo(n as Now) as Array<String> {
    var mod = n.h * 60 + n.m;
    if (seq == 0) {
      return ["8412/10000=", "0.8412"];
    }
    if (seq == 1) {
      return ["1440-" + mod + "=", (1440 - mod).toString()];
    }
    return ["24X60=", "1440"];
  }

  function render(dc as Dc, n as Now) as Void {
    dc.drawBitmap(0, 0, dial as BitmapResource);
    var disp = n.hhmm().substring(0, 2) + n.hhmm().substring(3, 5);
    var timeMode = true;
    var pressed = "";
    if (awake) {
      var dm = demo(n);
      var ks = (dm[0] as String).toCharArray();
      var kn = ks.size();
      if (ph < kn + 5) {
        timeMode = false;
        var k = ph < kn ? ph : kn - 1;
        var cur = "0";
        var fresh = true;
        for (var i = 0; i <= k; i++) {
          var c = ks[i];
          var cv = c.toNumber();
          if (cv >= 48 && cv <= 57) {
            cur = fresh ? c.toString() : cur + c;
            fresh = false;
          } else if (c == '=') {
            cur = dm[1] as String;
          } else {
            fresh = true;
          }
        }
        disp = cur;
        if (ph < kn) {
          pressed = ks[ph].toString();
        }
      }
    }
    var cs = disp.toCharArray();
    var vals = new [6] as Array<Number>;
    var dps = new [6] as Array<Boolean>;
    var cnt = 0;
    for (var i = 0; i < cs.size(); i++) {
      var cv = cs[i].toNumber();
      if (cv == 46) {
        if (cnt == 0) {
          vals[0] = 0;
          dps[0] = true;
          cnt = 1;
        } else {
          dps[cnt - 1] = true;
        }
      } else {
        if (cnt == 6) {
          for (var j = 0; j < 5; j++) {
            vals[j] = vals[j + 1];
            dps[j] = dps[j + 1];
          }
          cnt = 5;
        }
        vals[cnt] = cv == 45 ? 10 : cv - 48;
        dps[cnt] = false;
        cnt++;
      }
    }
    var off = 6 - cnt;
    for (var i = 0; i < 6; i++) {
      var k = i < off ? 11 : vals[i - off];
      cell(dc, k, 27 + 13 * i);
    }
    G.ink(dc);
    for (var i = 0; i < cnt; i++) {
      if (dps[i]) {
        dc.fillRectangle(30 + 13 * (i + off) + 11, 69, 2, 2);
      }
    }
    if (timeMode && (!awake || n.s % 2 == 0)) {
      dc.fillRectangle(79, 57, 2, 2);
      dc.fillRectangle(79, 64, 2, 2);
    }
    if (!pressed.equals("")) {
      for (var i = 0; i < 16; i++) {
        if (KEYS[i].equals(pressed)) {
          var px = 31 + (i % 4) * 30;
          var py = 84 + (i / 4) * 17;
          dc.fillRoundedRectangle(px, py, 24, 13, 2);
          G.paper(dc);
          G.t(dc, F.lab, F.lab_b, px + 12, py + 10, G.C, pressed);
          G.ink(dc);
        }
      }
    }
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, timeMode ? "TIME" : "CALC");
    G.t(dc, F.dd, F.dd_b, 144, 44, G.C, U.p2(n.d));
    G.t(dc, F.lab, F.lab_b, 144, 56, G.C, U.dowU(n));
  }
}
