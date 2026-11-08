import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class FaceView extends BaseFace {
  hidden const R = [
    ["ᚠ", "FEHU", "богатство"],
    ["ᚢ", "URUZ", "тур"],
    ["ᚦ", "THURISAZ", "великан"],
    ["ᚨ", "ANSUZ", "бог"],
    ["ᚱ", "RAIDO", "путь"],
    ["ᚲ", "KAUNAN", "факел"],
    ["ᚷ", "GEBO", "дар"],
    ["ᚹ", "WUNJO", "радость"],
    ["ᚺ", "HAGALAZ", "град"],
    ["ᚾ", "NAUDIZ", "нужда"],
    ["ᛁ", "ISAZ", "лёд"],
    ["ᛃ", "JERA", "год"],
    ["ᛇ", "EIHWAZ", "тис"],
    ["ᛈ", "PERTHRO", "жребий"],
    ["ᛉ", "ALGIZ", "лось"],
    ["ᛊ", "SOWILO", "солнце"],
    ["ᛏ", "TIWAZ", "Тюр"],
    ["ᛒ", "BERKANO", "берёза"],
    ["ᛖ", "EHWAZ", "конь"],
    ["ᛗ", "MANNAZ", "человек"],
    ["ᛚ", "LAGUZ", "вода"],
    ["ᛜ", "INGWAZ", "Инг"],
    ["ᛞ", "DAGAZ", "день"],
    ["ᛟ", "OTHALA", "наследие"]
  ] as Array<Array<String>>;
  hidden var stone as BitmapResource or Null;

  function initialize() {
    BaseFace.initialize();
    partialBox = [113, 0, 62, 62];
  }

  function onLayout(dc as Dc) as Void {
    F.load();
    stone = WatchUi.loadResource(Rez.Drawables.stone) as BitmapResource;
  }

  function render(dc as Dc, n as Now) as Void {
    var r = R[n.h];
    G.ink(dc);
    dc.drawBitmap(30, 40, stone as BitmapResource);
    G.ink(dc);
    G.t(dc, F.rn, F.rn_b, 65, 114, G.C, r[0]);
    G.t(dc, F.lab, F.lab_b, 106, 82, G.L, "AETT " + (n.h / 8 + 1));
    G.t(dc, F.lab, F.lab_b, 106, 94, G.L, r[1]);
    G.t(dc, F.mean, F.mean_b, 106, 106, G.L, r[2]);
    G.t(dc, F.time, F.time_b, 106, 128, G.L, n.hhmm());
    dc.drawLine(50, 146, 126, 146);
    dc.drawLine(50, 160, 126, 160);
    var total = n.m + 1;
    var grow = awake && n.s < 2 ? (n.s < 1 ? 0.3 : 0.7) : 1.0;
    for (var i = 0; i < total; i++) {
      var y = i < 30 ? 146 : 160;
      var j = i % 30;
      var x = 52 + (j / 5) * 12;
      var k = j % 5;
      var g = i == total - 1 ? grow : 1.0;
      if (k < 4) {
        var xx = x + k * 2.4;
        dc.drawLine(xx, y - 5, xx, y - 5 + 10 * g);
      } else {
        dc.drawLine(x - 1, y + 5, x - 1 + 9.4 * g, y + 5 - 10 * g);
      }
    }
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    sub(dc, n);
  }

  function renderPartial(dc as Dc, n as Now) as Void {
    sub(dc, n);
  }

  hidden function sub(dc as Dc, n as Now) as Void {
    G.t(dc, F.rs, F.rs_b, 144, 22, G.C, "ᛋᛖᚲ");
    G.t(dc, F.ss, F.ss_b, 144, 45, G.C, secLive() ? U.p2(n.s) : "--");
  }
}
