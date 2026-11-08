import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;
import Toybox.Weather;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden const SY = 44;
  hidden const X0 = 173;
  hidden const LEN = 1024;
  hidden const ART = [Rez.Drawables.clear, Rez.Drawables.partly, Rez.Drawables.cloudy, Rez.Drawables.fog,
    Rez.Drawables.rain0, Rez.Drawables.rain1, Rez.Drawables.rain2, Rez.Drawables.rain3,
    Rez.Drawables.snow0, Rez.Drawables.snow1, Rez.Drawables.snow2, Rez.Drawables.snow3];
  hidden const TY = [101, 101, 100, 100, 100, 100, 100, 99, 99, 99, 98, 98, 98, 97, 97, 97, 96, 96, 96, 96, 95, 95, 95, 95,
    94, 94, 94, 94, 93, 93, 93, 92, 92, 92, 91, 91, 91, 90, 90, 89, 89, 89, 88, 88, 88, 87, 86, 86, 85, 85, 84, 84, 83, 82,
    82, 81, 81, 80, 80, 79, 78, 78, 77, 76, 75, 75, 74, 73, 72, 71, 70, 69, 69, 68, 67, 66, 65, 64, 63, 62, 61, 60, 60, 60,
    60, 61];
  hidden const TL = [0, 10, 24, 34, 44, 54, 64, 78, 88, 98, 112, 122, 132, 147, 157, 167, 181, 191, 201, 211, 225, 235, 245,
    255, 269, 279, 289, 299, 313, 323, 333, 347, 357, 367, 381, 391, 401, 416, 426, 440, 450, 460, 474, 484, 494, 508, 522,
    532, 546, 556, 570, 580, 595, 609, 619, 633, 643, 657, 667, 681, 695, 705, 719, 734, 748, 758, 772, 786, 800, 814, 828,
    843, 853, 867, 881, 895, 909, 923, 937, 952, 966, 980, 990, 1000, 1010, 1024];
  hidden const DI = [1, 3, 6, 9, 11, 14, 16, 19, 22, 25, 28, 30, 33, 35, 38, 41, 43, 46, 48, 50, 53, 55, 58, 60, 63, 65, 67,
    69, 71, 74, 76, 78, 80, 83, 85];
  hidden const DCLOUD = [1073741823, 31];
  hidden const DFOG = [1071806649, 31];

  hidden var bmp as BitmapResource or Null = null;
  hidden var bid as Number = -1;
  hidden var key as Number = -1;
  hidden var kind as Number = 0;
  hidden var day as Boolean = false;
  hidden var temp as String or Null = null;
  hidden var shown as Number = -1;

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
    partialBox = [113, 0, 62, 62];
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function render(dc as Dc, n as Now) as Void {
    var k = n.h * 60 + n.m;
    if (k != key) {
      key = k;
      sense(n);
    }
    var ph = awake ? frame % 4 : 0;
    var id = kind == 2 ? 1 : kind == 3 ? 2 : kind == 6 ? 3 : kind == 4 ? 4 + ph : kind == 5 ? 8 + ph : 0;
    if (id != bid || bmp == null) {
      bmp = null;
      bmp = WatchUi.loadResource(ART[id]) as BitmapResource;
      bid = id;
    }
    dc.drawBitmap(0, SY, bmp as BitmapResource);
    G.ink(dc);
    G.t(dc, F.time, F.time_b, 14, 46, G.L, n.hhmm());
    if (kind == 1) {
      if (day) {
        G.paper(dc);
        dc.fillCircle(24, 67, 11);
        G.ink(dc);
        dc.fillCircle(24, 67, 8);
      } else {
        moon(dc, 24, 67, D.moonAge(n.epoch));
      }
    }
    trail(dc, kind == 3 || kind == 4 || kind == 6);
    caption(dc, n);
    sub(dc);
  }

  function onPartialUpdate(dc as Dc) as Void {
    if (D.hr() != shown) {
      BaseFace.onPartialUpdate(dc);
    }
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    sub(dc);
  }

  hidden function sense(n as Now) as Void {
    kind = 0;
    temp = null;
    if (Toybox has :Weather) {
      var c = Weather.getCurrentConditions();
      if (c != null) {
        var t = c.temperature;
        if (t != null && t > -100 && t < 100) {
          temp = Math.round(t).toNumber().toString();
        }
        var o = c.observationTime;
        if (c.condition != null && (o == null || Time.now().value() - o.value() < 7200)) {
          kind = classify(c.condition as Number);
        }
      }
    }
    var s = D.sunTimes();
    var now = Time.now().value();
    day = s != null ? now >= s[0] && now < s[1] : n.h >= 7 && n.h < 19;
    animMs = kind == 4 || kind == 5 ? 250 : 0;
  }

  hidden function classify(c as Number) as Number {
    if ([Weather.CONDITION_CLEAR, Weather.CONDITION_MOSTLY_CLEAR, Weather.CONDITION_FAIR, Weather.CONDITION_WINDY].indexOf(c) >= 0) {
      return 1;
    }
    if ([Weather.CONDITION_PARTLY_CLOUDY, Weather.CONDITION_PARTLY_CLEAR, Weather.CONDITION_THIN_CLOUDS,
        Weather.CONDITION_CHANCE_OF_SHOWERS, Weather.CONDITION_CHANCE_OF_THUNDERSTORMS, Weather.CONDITION_CHANCE_OF_SNOW,
        Weather.CONDITION_CHANCE_OF_RAIN_SNOW].indexOf(c) >= 0) {
      return 2;
    }
    if ([Weather.CONDITION_CLOUDY, Weather.CONDITION_MOSTLY_CLOUDY, Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN,
        Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW, Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW].indexOf(c) >= 0) {
      return 3;
    }
    if ([Weather.CONDITION_RAIN, Weather.CONDITION_LIGHT_RAIN, Weather.CONDITION_HEAVY_RAIN, Weather.CONDITION_SHOWERS,
        Weather.CONDITION_LIGHT_SHOWERS, Weather.CONDITION_HEAVY_SHOWERS, Weather.CONDITION_SCATTERED_SHOWERS,
        Weather.CONDITION_DRIZZLE, Weather.CONDITION_THUNDERSTORMS, Weather.CONDITION_SCATTERED_THUNDERSTORMS,
        Weather.CONDITION_HAIL, Weather.CONDITION_FREEZING_RAIN, Weather.CONDITION_SQUALL, Weather.CONDITION_TORNADO,
        Weather.CONDITION_HURRICANE, Weather.CONDITION_TROPICAL_STORM, Weather.CONDITION_UNKNOWN_PRECIPITATION].indexOf(c) >= 0) {
      return 4;
    }
    if ([Weather.CONDITION_SNOW, Weather.CONDITION_LIGHT_SNOW, Weather.CONDITION_HEAVY_SNOW, Weather.CONDITION_LIGHT_RAIN_SNOW,
        Weather.CONDITION_HEAVY_RAIN_SNOW, Weather.CONDITION_RAIN_SNOW, Weather.CONDITION_WINTRY_MIX, Weather.CONDITION_FLURRIES,
        Weather.CONDITION_SLEET, Weather.CONDITION_ICE, Weather.CONDITION_ICE_SNOW].indexOf(c) >= 0) {
      return 5;
    }
    if ([Weather.CONDITION_FOG, Weather.CONDITION_MIST, Weather.CONDITION_HAZY, Weather.CONDITION_HAZE, Weather.CONDITION_SMOKE,
        Weather.CONDITION_DUST, Weather.CONDITION_SAND, Weather.CONDITION_SANDSTORM, Weather.CONDITION_VOLCANIC_ASH].indexOf(c) >= 0) {
      return 6;
    }
    return 0;
  }

  hidden function moon(dc as Dc, cx as Number, cy as Number, age as Float) as Void {
    var r = 9;
    var p = age / 29.530588853;
    var k = Math.cos(2 * Math.PI * p);
    var b = (1 - k) / 2 > 0.02 ? 1.6 : 0.0;
    G.paper(dc);
    dc.fillCircle(cx, cy, r + 2);
    G.ink(dc);
    for (var dy = -r; dy <= r; dy++) {
      var w = Math.sqrt(r * r - dy * dy);
      var a = p < 0.5 ? cx + k * w - b : cx - w;
      var e = p < 0.5 ? cx + w : cx - k * w + b;
      if (e > a) {
        dc.drawLine(Math.round(a).toNumber(), cy + dy, Math.round(e).toNumber() + 1, cy + dy);
      }
    }
    dc.drawCircle(cx, cy, r);
  }

  hidden function trail(dc as Dc, hid as Boolean) as Void {
    var p = D.steps().toFloat() / D.stepGoal();
    if (p > 1) {
      p = 1.0;
    }
    var t = p * LEN;
    var n = TY.size();
    var i = 1;
    while (i < n - 1 && TL[i] < t) {
      i++;
    }
    if (hid) {
      var m = kind == 6 ? DFOG : DCLOUD;
      for (var j = 0; j < DI.size() && j * 30 < t; j++) {
        var q = DI[j];
        if (((m[j / 30] >> (j % 30)) & 1) == 1) {
          G.ink(dc);
        } else {
          G.paper(dc);
        }
        dc.fillRectangle(X0 - q, TY[q], 2, 2);
      }
    } else {
      G.paper(dc);
      for (var j = 1; j <= i; j++) {
        dc.fillRectangle(X0 - j, TY[j] - 1, 2, 2);
      }
    }
    if (i < 4) {
      i = 4;
    }
    var x = X0 - i;
    var y = TY[i];
    G.paper(dc);
    dc.fillCircle(x, y, 6);
    G.ink(dc);
    dc.fillCircle(x, y, 5);
    G.paper(dc);
    dc.fillCircle(x, y, 2);
  }

  hidden function caption(dc as Dc, n as Now) as Void {
    var f = F.lab as FontResource;
    var a = U.dowU(n) + " " + n.d + " " + U.monU(n);
    var s = D.steps().toString();
    var l = temp == null ? "--" : temp as String;
    var r = temp == null ? "" : "C";
    var o = temp == null ? 0 : 5;
    var g = "   ";
    if (dc.getTextWidthInPixels(a + g + l + r + g + s, f) + o > 124) {
      g = " ";
    }
    l = a + g + l;
    r = r + g + s;
    var wl = dc.getTextWidthInPixels(l, f);
    var x = Math.round(88 - (wl + o + dc.getTextWidthInPixels(r, f)) / 2.0).toNumber();
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, x, 161, G.L, l);
    if (temp != null) {
      dc.drawRectangle(x + wl + 1, 156, 3, 3);
    }
    G.t(dc, F.lab, F.lab_b, x + wl + o, 161, G.L, r);
  }

  hidden function sub(dc as Dc) as Void {
    G.paper(dc);
    dc.fillCircle(144, 31, 31);
    G.ink(dc);
    G.t(dc, F.lab, F.lab_b, 144, 17, G.C, "HR");
    var h = D.hr();
    shown = h;
    G.t(dc, F.hr, F.hr_b, 144, 41, G.C, h > 0 ? h.toString() : "--");
    G.t(dc, F.lab, F.lab_b, 144, 52, G.C, "BPM");
  }
}
