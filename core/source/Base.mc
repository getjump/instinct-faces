import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

class FaceApp extends Application.AppBase {
  function initialize() {
    AppBase.initialize();
  }

  function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
    var view = new FaceView();
    return [view, new FaceDelegate(view)];
  }
}

class FaceDelegate extends WatchUi.WatchFaceDelegate {
  hidden var view as BaseFace;

  function initialize(v as BaseFace) {
    WatchFaceDelegate.initialize();
    view = v;
  }

  function onPowerBudgetExceeded(info as WatchUi.WatchFacePowerInfo) as Void {
    view.partialOk = false;
    report(info);
  }

  (:debug)
  hidden function report(info as WatchUi.WatchFacePowerInfo) as Void {
    System.println("Error: power budget " + info.executionTimeAverage + " > " + info.executionTimeLimit);
  }

  (:release)
  hidden function report(info as WatchUi.WatchFacePowerInfo) as Void {
  }
}

class BaseFace extends WatchUi.WatchFace {
  var awake as Boolean = true;
  var frame as Number = 0;
  var animMs as Number = 0;
  var partialBox as [Number, Number, Number, Number] or Null = null;
  var partialOk as Boolean = true;
  hidden var timer as Timer.Timer or Null = null;

  function initialize() {
    WatchFace.initialize();
  }

  function onShow() as Void {
    startAnim();
  }

  function onHide() as Void {
    stopAnim();
  }

  function onExitSleep() as Void {
    awake = true;
    trace("WAKE");
    startAnim();
    WatchUi.requestUpdate();
  }

  function onEnterSleep() as Void {
    awake = false;
    trace("SLEEP");
    stopAnim();
    WatchUi.requestUpdate();
  }

  hidden function startAnim() as Void {
    if (animMs > 0 && awake && timer == null) {
      timer = new Timer.Timer();
      (timer as Timer.Timer).start(method(:tick), animMs, true);
    }
  }

  hidden function stopAnim() as Void {
    if (timer != null) {
      (timer as Timer.Timer).stop();
      timer = null;
    }
  }

  function tick() as Void {
    frame++;
    step();
    WatchUi.requestUpdate();
  }

  function onUpdate(dc as Dc) as Void {
    var t0 = System.getTimer();
    if (dc has :clearClip) {
      dc.clearClip();
    }
    dc.setColor(Theme.FG, Theme.BG);
    dc.clear();
    render(dc, new Now());
    probe(t0);
  }

  (:debug)
  hidden function trace(s as String) as Void {
    System.println(s);
  }

  (:release)
  hidden function trace(s as String) as Void {
  }

  (:debug)
  hidden function probe(t0 as Number) as Void {
    var s = System.getSystemStats();
    System.println("P " + (System.getTimer() - t0) + " " + s.usedMemory + " " + s.totalMemory);
  }

  (:release)
  hidden function probe(t0 as Number) as Void {
  }

  function onPartialUpdate(dc as Dc) as Void {
    if (partialBox == null || !partialOk) {
      return;
    }
    var b = partialBox as [Number, Number, Number, Number];
    dc.setClip(b[0], b[1], b[2], b[3]);
    dc.setColor(Theme.BG, Theme.BG);
    dc.fillRectangle(b[0], b[1], b[2], b[3]);
    dc.setColor(Theme.FG, Theme.BG);
    trace("PART");
    renderPartial(dc, new Now());
    dc.clearClip();
  }

  function secLive() as Boolean {
    return awake || (partialBox != null && partialOk);
  }

  function step() as Void {
  }

  function render(dc as Dc, n as Now) as Void {
  }

  function renderPartial(dc as Dc, n as Now) as Void {
  }
}

class Now {
  var y as Number;
  var mon as Number;
  var d as Number;
  var dow as Number;
  var h as Number;
  var m as Number;
  var s as Number;
  var epoch as Number;

  function initialize() {
    var t = Time.now();
    var i = Time.Gregorian.info(t, Time.FORMAT_SHORT);
    y = i.year as Number;
    mon = i.month as Number;
    d = i.day as Number;
    dow = (i.day_of_week as Number) - 1;
    h = i.hour;
    m = i.min;
    s = i.sec;
    epoch = t.value();
  }

  function doy() as Number {
    var o = Time.Gregorian.moment({:year => y, :month => 1, :day => 1, :hour => 0, :minute => 0, :second => 0});
    var o2 = Time.Gregorian.moment({:year => y, :month => mon, :day => d, :hour => 0, :minute => 0, :second => 0});
    return (o2.value() - o.value()) / 86400 + 1;
  }

  function hhmm() as String {
    return U.p2(h) + ":" + U.p2(m);
  }
}

module U {
  const DOW = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"] as Array<String>;
  const MON = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"] as Array<String>;

  function p2(v as Number) as String {
    return (v < 10 ? "0" : "") + v;
  }

  function dowU(n as Now) as String {
    return DOW[n.dow];
  }

  function dowL(n as Now) as String {
    return DOW[n.dow].toLower();
  }

  function monU(n as Now) as String {
    return MON[n.mon - 1];
  }
}

module G {
  const L = Graphics.TEXT_JUSTIFY_LEFT;
  const C = Graphics.TEXT_JUSTIFY_CENTER;
  const R = Graphics.TEXT_JUSTIFY_RIGHT;

  function ink(dc as Dc) as Void {
    dc.setColor(Theme.FG, Graphics.COLOR_TRANSPARENT);
  }

  function paper(dc as Dc) as Void {
    dc.setColor(Theme.BG, Graphics.COLOR_TRANSPARENT);
  }

  function t(dc as Dc, font as FontResource or Null, base as Number, x as Numeric, y as Numeric, just as Number, s as String) as Void {
    dc.drawText(x, y - base, font as FontResource, s, just);
  }

  function rot(pts as Array<Array<Numeric>>, cx as Numeric, cy as Numeric, deg as Numeric) as Array<[Numeric, Numeric]> {
    var a = Math.toRadians(deg);
    var c = Math.cos(a);
    var s = Math.sin(a);
    var out = new [pts.size()] as Array<[Numeric, Numeric]>;
    for (var i = 0; i < pts.size(); i++) {
      var dx = pts[i][0] - cx;
      var dy = pts[i][1] - cy;
      out[i] = [cx + dx * c - dy * s, cy + dx * s + dy * c] as [Numeric, Numeric];
    }
    return out;
  }

  function hand(dc as Dc, pts as Array<Array<Numeric>>, cx as Numeric, cy as Numeric, deg as Numeric) as Void {
    dc.fillPolygon(rot(pts, cx, cy, deg) as Array<[Numeric, Numeric]>);
  }

  function ring(dc as Dc, cx as Numeric, cy as Numeric, r1 as Numeric, r2 as Numeric, deg as Numeric) as Void {
    var a = Math.toRadians(deg);
    var sn = Math.sin(a);
    var cs = Math.cos(a);
    dc.drawLine(cx + r1 * sn, cy - r1 * cs, cx + r2 * sn, cy - r2 * cs);
  }

  function moon(dc as Dc, cx as Number, cy as Number, r as Number, phase as Float) as Void {
    var k = Math.cos(2 * Math.PI * phase);
    var side = phase < 0.5 ? 1 : -1;
    for (var dy = -r; dy <= r; dy++) {
      var w = Math.sqrt(r * r - dy * dy);
      dc.drawLine(cx + (side * k * w).toNumber(), cy + dy, cx + (side * w).toNumber() + side, cy + dy);
    }
  }
}
