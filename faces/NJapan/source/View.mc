import Toybox.Graphics;
import Toybox.Lang;

class FaceView extends BaseFace {
  hidden const W = [
    ["時計", "とけい", "tokei / часы"],
    ["旅", "たび", "tabi / путешествие"],
    ["駅", "えき", "eki / станция"],
    ["電車", "でんしゃ", "densha / электричка"],
    ["切符", "きっぷ", "kippu / билет"],
    ["宿", "やど", "yado / ночлег"],
    ["山", "やま", "yama / гора"],
    ["海", "うみ", "umi / море"],
    ["空", "そら", "sora / небо"],
    ["雨", "あめ", "ame / дождь"],
    ["雪", "ゆき", "yuki / снег"],
    ["風", "かぜ", "kaze / ветер"],
    ["月", "つき", "tsuki / луна"],
    ["星", "ほし", "hoshi / звезда"],
    ["朝", "あさ", "asa / утро"],
    ["夜", "よる", "yoru / ночь"],
    ["道", "みち", "michi / дорога"],
    ["茶", "ちゃ", "cha / чай"],
    ["水", "みず", "mizu / вода"],
    ["猫", "ねこ", "neko / кошка"],
    ["花", "はな", "hana / цветок"],
    ["橋", "はし", "hashi / мост"],
    ["町", "まち", "machi / городок"],
    ["地図", "ちず", "chizu / карта"]
  ] as Array<Array<String>>;

  function initialize() {
    BaseFace.initialize();
    animMs = 500;
  }

  function onLayout(dc as Dc) as Void {
    F.load();
  }

  function render(dc as Dc, n as Now) as Void {
    var idx = n.h;
    var phase = 99;
    if (awake) {
      idx = (n.h + frame / 8) % 24;
      phase = frame % 8;
    }
    var w = W[idx];
    G.ink(dc);
    G.t(dc, F.time, F.time_b, 30, 44, G.L, n.hhmm());
    G.t(dc, F.cnt, F.cnt_b, 30, 58, G.L, "WORD " + (idx + 1) + "/24");
    G.t(dc, F.kj, F.kj_b, 80, 122, G.C, w[0]);
    if (phase >= 3) {
      G.t(dc, F.kn, F.kn_b, 88, 142, G.C, w[1]);
      dc.fillRectangle(44, 128, 88, 1);
    }
    if (phase >= 5) {
      G.t(dc, F.tr, F.tr_b, 88, 158, G.C, w[2]);
    }
    G.paper(dc);
    dc.fillRectangle(113, 1, 62, 62);
    G.ink(dc);
    var th = (n.epoch / 3600 + 9) % 24;
    var tm = n.epoch / 60 % 60;
    G.t(dc, F.lab, F.lab_b, 144, 20, G.C, "TYO");
    G.t(dc, F.tyo, F.tyo_b, 144, 42, G.C, U.p2(th) + ":" + U.p2(tm));
    G.t(dc, F.tk, F.tk_b, 144, 56, G.C, "東京");
  }
}
