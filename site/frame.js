"use strict";

(() => {
  const RealDate = Date;
  let clock = { base: RealDate.now(), anchor: RealDate.now(), speed: 1 };
  const virtualNow = () => Math.floor(clock.base + (RealDate.now() - clock.anchor) * clock.speed);

  class ClockDate extends RealDate {
    constructor(...args) {
      if (args.length === 0) super(virtualNow());
      else super(...args);
    }

    static now() {
      return virtualNow();
    }
  }
  globalThis.Date = ClockDate;

  const root = document.getElementById("root");
  let design = null;
  let props = {};
  let comp = null;
  let queued = false;
  let failed = false;
  let rendered = false;

  const post = (msg) => parent.postMessage(msg, "*");

  function fail(err) {
    if (failed) return;
    failed = true;
    post({ type: "error", message: String((err && err.message) || err) });
  }

  class DCLogic {
    constructor() {
      this.props = {};
      this.state = {};
    }

    setState(patch) {
      Object.assign(this.state, typeof patch === "function" ? patch(this.state, this.props) : patch);
      schedule();
    }
  }

  const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  const formats = new Map();
  const pad = (n) => String(n).padStart(2, "0");

  function parts(date, zone) {
    let fmt = formats.get(zone);
    if (!fmt) {
      fmt = new Intl.DateTimeFormat("en-US", {
        timeZone: zone,
        hourCycle: "h23",
        weekday: "short",
        year: "numeric",
        month: "numeric",
        day: "numeric",
        hour: "numeric",
        minute: "numeric",
        second: "numeric",
      });
      formats.set(zone, fmt);
    }
    const p = {};
    for (const { type, value } of fmt.formatToParts(date)) p[type] = value;
    return p;
  }

  function offsetMinutes(date, zone) {
    const p = parts(date, zone);
    const wall = Date.UTC(+p.year, +p.month - 1, +p.day, +p.hour % 24, +p.minute, +p.second);
    return Math.round((wall - Math.floor(date.getTime() / 1000) * 1000) / 60000);
  }

  function signedHours(minutes) {
    const a = Math.abs(minutes);
    return (minutes < 0 ? "-" : "+") + Math.floor(a / 60) + (a % 60 ? ":" + pad(a % 60) : "");
  }

  function clockText(format, date) {
    return format.replace(/\{(\w+)(?:@([\w/+-]+))?\}/g, (token, name, zone) => {
      const p = parts(date, zone);
      const month = +p.month;
      switch (name) {
        case "hh":
          return pad(+p.hour % 24);
        case "mi":
          return pad(+p.minute);
        case "ss":
          return pad(+p.second);
        case "dd":
          return pad(+p.day);
        case "mo":
          return pad(month);
        case "doy":
          return String((Date.UTC(+p.year, month - 1, +p.day) - Date.UTC(+p.year, 0, 1)) / 864e5 + 1);
        case "wd":
          return p.weekday.toLowerCase();
        case "WD":
          return p.weekday.toUpperCase();
        case "mon":
          return MONTHS[month - 1].toLowerCase();
        case "MON":
          return MONTHS[month - 1].toUpperCase();
        case "tz":
          return signedHours(offsetMinutes(date));
        case "off":
          return signedHours(offsetMinutes(date, zone) - offsetMinutes(date));
        default:
          return token;
      }
    });
  }

  function clockVals(spec) {
    const now = new Date();
    const out = {};
    for (const [key, format] of Object.entries(spec)) out[key] = clockText(format, now);
    return out;
  }

  function lookup(vals, path) {
    let v = vals;
    for (const key of path.split(".")) v = v == null ? undefined : v[key];
    return v == null ? "" : String(v);
  }

  function render() {
    queued = false;
    if (!comp) return;
    try {
      const vals = typeof comp.renderVals === "function" ? comp.renderVals() || {} : {};
      if (design.clock && Object.keys(design.clock).length) vals.clock = clockVals(design.clock);
      root.innerHTML = design.template.replace(/\{\{\s*([\w.]+)\s*\}\}/g, (_, key) => lookup(vals, key));
      if (!rendered) {
        rendered = true;
        document.fonts.ready.then(() => setTimeout(() => post({ type: "rendered" }), 50));
      }
    } catch (err) {
      fail(err);
    }
  }

  function schedule() {
    if (queued) return;
    queued = true;
    setTimeout(render, 0);
  }

  function unmount() {
    if (comp && typeof comp.componentWillUnmount === "function") {
      try {
        comp.componentWillUnmount();
      } catch (err) {
        fail(err);
      }
    }
    comp = null;
  }

  function mount() {
    unmount();
    failed = false;
    try {
      const Component = new Function("DCLogic", `${design.script}\nreturn Component;`)(DCLogic);
      comp = new Component();
      comp.props = { ...props };
      if (typeof comp.componentDidMount === "function") comp.componentDidMount();
    } catch (err) {
      fail(err);
    }
    render();
  }

  function loadAssets(d) {
    const style = document.createElement("style");
    style.textContent = d.style;
    document.head.appendChild(style);
    const loads = d.fonts.map(
      (href) =>
        new Promise((resolve) => {
          const link = document.createElement("link");
          link.rel = "stylesheet";
          link.href = href;
          link.onload = link.onerror = resolve;
          document.head.appendChild(link);
        }),
    );
    return Promise.race([Promise.all(loads), new Promise((resolve) => setTimeout(resolve, 3000))]);
  }

  addEventListener("message", (ev) => {
    if (ev.source !== parent || !ev.data) return;
    const msg = ev.data;
    if (msg.clock) clock = msg.clock;
    if (msg.type === "mount") {
      design = msg.design;
      props = msg.props || {};
      loadAssets(design).then(mount);
    } else if (msg.type === "props" && design) {
      props = msg.props || {};
      mount();
    } else if (msg.type === "clock") {
      schedule();
    }
  });

  setInterval(schedule, 1000);
  post({ type: "ready" });
})();
