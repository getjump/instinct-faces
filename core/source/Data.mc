import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;

module D {
  function hr() as Number {
    var i = Activity.getActivityInfo();
    if (i != null && i.currentHeartRate != null) {
      return i.currentHeartRate as Number;
    }
    if (ActivityMonitor has :getHeartRateHistory) {
      var s = ActivityMonitor.getHeartRateHistory(1, true).next();
      if (s != null && s.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
        return s.heartRate;
      }
    }
    return 0;
  }

  function steps() as Number {
    var v = ActivityMonitor.getInfo().steps;
    return v == null ? 0 : v;
  }

  function stepGoal() as Number {
    var v = ActivityMonitor.getInfo().stepGoal;
    return v == null || v == 0 ? 10000 : v;
  }

  function stepHistory() as Array<Number> {
    var h = ActivityMonitor.getHistory();
    var out = [] as Array<Number>;
    if (h != null) {
      for (var i = 0; i < h.size(); i++) {
        var v = h[i].steps;
        out.add(v == null ? 0 : v);
      }
    }
    return out;
  }

  function batt() as Number {
    return System.getSystemStats().battery.toNumber();
  }

  function battDays() as Number {
    var v = System.getSystemStats().batteryInDays;
    return v == null ? 0 : v.toNumber();
  }

  function solar() as Number {
    var v = System.getSystemStats().solarIntensity;
    return v == null || v < 0 ? 0 : v;
  }

  function moonAge(epoch as Number) as Float {
    var syn = 29.530588853;
    var days = (epoch - 947182440) / 86400.0;
    var a = days - syn * Math.floor(days / syn);
    return a.toFloat();
  }

  function moonIllum(age as Float) as Float {
    return ((1.0 - Math.cos(2 * Math.PI * age / 29.530588853)) / 2.0).toFloat();
  }

  function moonName(age as Float) as String {
    var names = ["NEW", "WXC", "1Q", "WXG", "FUL", "WNG", "3Q", "WNC"];
    return names[((age / 29.530588853) * 8 + 0.5).toNumber() % 8];
  }

  function location() as Position.Location or Null {
    var i = Activity.getActivityInfo();
    if (i != null && i.currentLocation != null) {
      return i.currentLocation;
    }
    if (Toybox has :Weather) {
      var c = Weather.getCurrentConditions();
      if (c != null && c.observationLocationPosition != null) {
        return c.observationLocationPosition;
      }
    }
    return null;
  }

  function sunTimes() as [Number, Number] or Null {
    var loc = location();
    if (loc == null || !(Toybox has :Weather)) {
      return null;
    }
    var now = Time.now();
    var r = Weather.getSunrise(loc, now);
    var s = Weather.getSunset(loc, now);
    if (r == null || s == null) {
      return null;
    }
    var rise = r.value();
    var set = s.value();
    return [rise, set < rise ? set + 86400 : set];
  }
}
