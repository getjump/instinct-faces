import Toybox.Graphics;
import Toybox.Lang;

class FaceView extends BaseFace {
  hidden const KO_MD = [1023, 1028, 1102, 1107, 1112, 1117, 1122, 1127, 1202, 1207, 1212, 1216] as Array<Number>;
  hidden const KO = [
    ["霜降", "霜始降", "しもはじめてふ", "る", "Выпадает", "первый иней", 0],
    ["霜降", "霎時施", "こさめときどき", "ふる", "Временами", "моросит", 1],
    ["霜降", "楓蔦黄", "もみじつたきば", "む", "Желтеют клёны", "и плющ", 2],
    ["立冬", "山茶始開", "つばきはじめて", "ひらく", "Зацветают", "камелии", 0],
    ["立冬", "地始凍", "ちはじめてこお", "る", "Земля начинает", "мёрзнуть", 1],
    ["立冬", "金盞香", "きんせんかさく", "", "Благоухают", "нарциссы", 2],
    ["小雪", "虹蔵不見", "にじかくれてみ", "えず", "Радуги", "прячутся", 0],
    ["小雪", "朔風払葉", "きたかぜこのは", "をはらう", "Северный ветер", "срывает листья", 1],
    ["小雪", "橘始黄", "たちばなはじめ", "てきばむ", "Желтеют", "мандарины", 2],
    ["大雪", "閉塞成冬", "そらさむくふゆ", "となる", "Холодает,", "приходит зима", 0],
    ["大雪", "熊蟄穴", "くまあなにこも", "る", "Медведи уходят", "в берлоги", 1],
    ["大雪", "鱖魚群", "さけのうおむら", "がる", "Лосось идёт", "косяками", 2]
  ] as Array<Array<Object>>;
  hidden const SK_MD = [105, 120, 204, 219, 305, 320, 404, 420, 505, 521, 605, 621, 707, 722, 807, 823, 907, 922, 1008, 1023, 1107, 1122, 1207, 1221] as Array<Number>;
  hidden const SK = ["小寒", "大寒", "立春", "雨水", "啓蟄", "春分", "清明", "穀雨", "立夏", "小満", "芒種", "夏至", "小暑", "大暑", "立秋", "処暑", "白露", "秋分", "寒露", "霜降", "立冬", "小雪", "大雪", "冬至"] as Array<String>;
  hidden const NUM = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"] as Array<String>;
  hidden const POS = ["初候", "次候", "末候"] as Array<String>;
  hidden var revealAt as Number = 0;

  function initialize() {
    BaseFace.initialize();
    animMs = 250;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function onExitSleep() as Void {
    revealAt = frame;
    BaseFace.onExitSleep();
  }

  hidden function kn(v as Number) as String {
    if (v < 10) {
      return NUM[v];
    }
    var t = v / 10;
    var o = v % 10;
    return (t == 1 ? "" : NUM[t]) + "十" + (o > 0 ? NUM[o] : "");
  }

  hidden function ch(s as String, i as Number) as String {
    return i < s.length() ? s.substring(i, i + 1) as String : "";
  }

  function render(dc as Dc, n as Now) as Void {
    var md = n.mon * 100 + n.d;
    var sk = 11;
    for (var i = 0; i < SK_MD.size(); i++) {
      if (md >= SK_MD[i]) {
        sk = i;
      }
    }
    var name = SK[sk];
    var kana1 = "";
    var kana2 = "";
    var ru1 = "";
    var ru2 = "";
    var pos = 0;
    if (md < 1221 && md >= 1023) {
      var e = 0;
      for (var i = 0; i < KO_MD.size(); i++) {
        if (md >= KO_MD[i]) {
          e = i;
        }
      }
      name = KO[e][1] as String;
      kana1 = KO[e][2] as String;
      kana2 = KO[e][3] as String;
      ru1 = KO[e][4] as String;
      ru2 = KO[e][5] as String;
      pos = KO[e][6] as Number;
    }
    var sekki = SK[sk];
    var el = awake ? frame - revealAt : 99;
    G.ink(dc);
    G.t(dc, F.t26, F.t26_b, 24, 50, G.L, n.hhmm());
    G.t(dc, F.k11, F.k11_b, 24, 66, G.L, kn(n.mon) + "月" + kn(n.d) + "日");
    G.t(dc, F.k8, F.k8_b, 24, 86, G.L, kana1);
    G.t(dc, F.k8, F.k8_b, 24, 96, G.L, kana2);
    G.t(dc, F.k9, F.k9_b, 24, 114, G.L, ru1);
    G.t(dc, F.k9, F.k9_b, 24, 126, G.L, ru2);
    dc.drawLine(104, 64, 104, 160);
    for (var i = 0; i < 4; i++) {
      if (el >= i) {
        G.t(dc, F.k24, F.k24_b, 120, 86 + i * 24, G.C, ch(name, i));
      }
    }
    dc.fillRoundedRectangle(50, 136, 28, 28, 3);
    G.paper(dc);
    dc.drawRoundedRectangle(52, 138, 24, 24, 2);
    G.t(dc, F.k11, F.k11_b, 64, 149, G.C, ch(sekki, 0));
    G.t(dc, F.k11, F.k11_b, 64, 160, G.C, ch(sekki, 1));
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    G.t(dc, F.k9, F.k9_b, 144, 20, G.C, "七十二候");
    G.t(dc, F.k18, F.k18_b, 144, 42, G.C, POS[pos]);
    G.t(dc, F.k9, F.k9_b, 144, 56, G.C, sekki);
  }
}
