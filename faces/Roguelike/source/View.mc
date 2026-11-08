import Toybox.Graphics;
import Toybox.Lang;
import Toybox.UserProfile;

class FaceView extends BaseFace {
  function initialize() {
    BaseFace.initialize();
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function render(dc as Dc, n as Now) as Void {
    G.ink(dc);
    var hr = D.hr();
    var batt = D.batt();
    var steps = D.steps();
    var goal = D.stepGoal();
    var pct = steps * 100 / goal;
    if (pct > 100) {
      pct = 100;
    }
    var left = goal - steps;
    if (left < 0) {
      left = 0;
    }
    G.t(dc, F.lab, F.lab_b, 28, 36, G.L, U.dowU(n) + " DAY " + n.doy());
    G.t(dc, F.lab, F.lab_b, 22, 102, G.L, "HP");
    G.t(dc, F.lab, F.lab_b, 22, 115, G.L, "ST");
    G.t(dc, F.lab, F.lab_b, 22, 128, G.L, "XP");
    G.t(dc, F.lab, F.lab_b, 130, 102, G.L, hr > 0 ? hr.toString() : "--");
    G.t(dc, F.lab, F.lab_b, 130, 115, G.L, batt.toString());
    G.t(dc, F.lab, F.lab_b, 130, 128, G.L, pct + "%");
    G.t(dc, F.lab, F.lab_b, 88, 145, G.C, "> " + left + " TO LVL UP");
    var rhr = resting();
    G.t(dc, F.lab, F.lab_b, 70, 160, G.L, rhr > 0 ? rhr.toString() : "--");
    var bd = D.battDays();
    G.t(dc, F.lab, F.lab_b, 102, 160, G.L, bd > 0 ? bd + "D" : "--");
    G.t(dc, F.time, F.time_b, 12, 80, G.L, n.hhmm());
    dc.drawRectangle(40, 95, 85, 7);
    dc.drawRectangle(40, 108, 85, 7);
    dc.drawRectangle(40, 121, 85, 7);
    var w = hr * 4 / 5;
    if (w > 82) {
      w = 82;
    }
    dc.fillRectangle(42, 97, w, 4);
    dither(dc, 42, 110, batt * 84 / 100);
    var xw = pct * 84 / 100;
    for (var i = 0; i < 21; i++) {
      var sw = xw - i * 4;
      if (sw <= 0) {
        break;
      }
      dc.fillRectangle(42 + i * 4, 123, sw > 3 ? 3 : sw, 4);
    }
    heart(dc);
    sun(dc);
    hero(dc);
    G.t(dc, F.lab, F.lab_b, 144, 52, G.C, "IDLE");
  }

  hidden function resting() as Number {
    var p = UserProfile.getProfile();
    if (p != null && p.restingHeartRate != null) {
      return p.restingHeartRate as Number;
    }
    return 0;
  }

  hidden function dither(dc as Dc, x as Number, y as Number, w as Number) as Void {
    for (var py = y; py < y + 4; py++) {
      for (var px = x; px < x + w; px++) {
        if (((px + py) & 1) == 0) {
          dc.drawPoint(px, py);
        }
      }
    }
  }

  hidden function heart(dc as Dc) as Void {
    dc.fillRectangle(61, 153, 2, 1);
    dc.fillRectangle(64, 153, 2, 1);
    dc.fillRectangle(60, 154, 7, 2);
    dc.fillRectangle(61, 156, 5, 1);
    dc.fillRectangle(62, 157, 3, 1);
    dc.fillRectangle(63, 158, 1, 1);
  }

  hidden function sun(dc as Dc) as Void {
    dc.fillRectangle(94, 155, 3, 3);
    dc.fillRectangle(95, 153, 1, 1);
    dc.fillRectangle(95, 159, 1, 1);
    dc.fillRectangle(92, 156, 1, 1);
    dc.fillRectangle(98, 156, 1, 1);
    dc.fillRectangle(93, 154, 1, 1);
    dc.fillRectangle(97, 154, 1, 1);
    dc.fillRectangle(93, 158, 1, 1);
    dc.fillRectangle(97, 158, 1, 1);
  }

  hidden function hero(dc as Dc) as Void {
    dc.fillRectangle(140, 12, 8, 2);
    dc.fillRectangle(152, 12, 2, 10);
    dc.fillRectangle(138, 14, 12, 2);
    dc.fillRectangle(138, 16, 4, 2);
    dc.fillRectangle(146, 16, 4, 2);
    dc.fillRectangle(138, 18, 12, 2);
    dc.fillRectangle(140, 20, 8, 2);
    dc.fillRectangle(136, 22, 18, 2);
    dc.fillRectangle(134, 24, 2, 4);
    dc.fillRectangle(138, 24, 16, 2);
    dc.fillRectangle(138, 26, 12, 4);
    dc.fillRectangle(138, 30, 4, 4);
    dc.fillRectangle(146, 30, 4, 4);
    dc.fillRectangle(136, 34, 6, 2);
    dc.fillRectangle(146, 34, 6, 2);
    for (var x = 128; x < 160; x += 2) {
      dc.drawPoint(x, 38);
    }
  }
}
