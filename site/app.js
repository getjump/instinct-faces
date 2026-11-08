const CASE_COLORS = ["#2b2d29", "#56603f", "#b5472b", "#cfc9ba"];
const SCREEN = {
  light: { bg: "#c6c9bc", ink: "#161713" },
  dark: { bg: "#141512", ink: "#d7dacd" },
};
const PROP_LABELS = { mode: "Screen", caseColor: "Case", demo: "Demo motion", rule: "Rule" };
const PREFS_KEY = "instinct-faces:prefs";
const SPEEDS = [1, 60, 600, 0];

const $ = (sel, root = document) => root.querySelector(sel);
const el = (tag, attrs = {}, ...kids) => {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (v == null || v === false) continue;
    if (k === "class") node.className = v;
    else if (k === "text") node.textContent = v;
    else if (k.startsWith("on")) node.addEventListener(k.slice(2), v);
    else node.setAttribute(k, v === true ? "" : v);
  }
  node.append(...kids.filter((k) => k != null));
  return node;
};

const prefs = {
  view: "live",
  frame: "awake",
  mode: "light",
  caseColor: CASE_COLORS[0],
  demo: true,
};
try {
  Object.assign(prefs, JSON.parse(localStorage.getItem(PREFS_KEY) || "{}"));
} catch {
  /* storage unavailable */
}
const savePrefs = () => {
  try {
    localStorage.setItem(PREFS_KEY, JSON.stringify(prefs));
  } catch {
    /* storage unavailable */
  }
};

let clock = { base: Date.now(), anchor: Date.now(), speed: 1 };
const virtualNow = () => clock.base + (Date.now() - clock.anchor) * clock.speed;
const setClock = (patch) => {
  const now = Date.now();
  clock = { base: virtualNow(), anchor: now, speed: clock.speed, ...patch };
  for (const stage of Stage.live) stage.post({ type: "clock" });
};

let index = null;
let runtime = "";
const designs = new Map();
const frameDoc = () =>
  '<!doctype html><html><head><meta charset="utf-8"><meta name="color-scheme" content="light">' +
  "<style>html,body{margin:0;overflow:hidden;" +
  `background:transparent}</style></head><body><div id="root"></div><script>${runtime}</script></body></html>`;
const loadDesign = (name) => {
  if (!designs.has(name))
    designs.set(
      name,
      fetch(`designs/${name}.json`).then((r) => r.json()),
    );
  return designs.get(name);
};

const baseProps = (face) => {
  const props = {};
  for (const [key, spec] of Object.entries(face.props)) if ("default" in spec) props[key] = spec.default;
  return { ...props, mode: prefs.mode, caseColor: prefs.caseColor, demo: prefs.demo };
};

function buildSvg(face, frame, mode, caseColor) {
  const display =
    `<image href="frames/${face.name}.${frame}.${mode}.png" x="32" y="52" width="176" height="176" ` +
    `preserveAspectRatio="none" style="image-rendering:pixelated"/>`;
  return index.case
    .replace("{{display}}", display)
    .replace(/\{\{\s*caseColor\s*\}\}/g, caseColor)
    .replace(/\{\{\s*bg\s*\}\}/g, SCREEN[mode].bg)
    .replace(/\{\{\s*ink\s*\}\}/g, SCREEN[mode].ink);
}

class Stage {
  static live = new Set();
  static byWindow = new Map();

  constructor(face, { props = null } = {}) {
    this.face = face;
    this.props = props;
    this.frame = null;
    this.el = el("div", { class: "stage" });
    this.build = el("div", { class: "build" });
    this.el.append(this.build);
    new ResizeObserver(([entry]) => {
      this.el.style.setProperty("--s", entry.contentRect.width / 480);
    }).observe(this.el);
  }

  currentProps() {
    return this.props || baseProps(this.face);
  }

  paint() {
    const p = this.currentProps();
    this.build.innerHTML = buildSvg(this.face, prefs.frame, p.mode, p.caseColor);
    const live = prefs.view === "live" && this.face.design;
    this.el.classList.toggle("is-live", Boolean(live && this.frame && this.frame.dataset.on));
  }

  mount() {
    if (this.frame || !this.face.design) return;
    this.frame = el("iframe", {
      sandbox: "allow-scripts",
      srcdoc: frameDoc(),
      title: `${this.face.title}, live design`,
      tabindex: "-1",
      loading: "eager",
    });
    this.el.append(this.frame);
    Stage.live.add(this);
  }

  unmount() {
    if (!this.frame) return;
    Stage.byWindow.delete(this.frame.contentWindow);
    this.frame.remove();
    this.frame = null;
    Stage.live.delete(this);
    this.el.classList.remove("is-live", "has-error");
  }

  post(msg) {
    if (this.frame && this.frame.contentWindow) this.frame.contentWindow.postMessage({ ...msg, clock }, "*");
  }

  async onMessage(msg) {
    if (msg.type === "ready") {
      const design = await loadDesign(this.face.name);
      this.post({ type: "mount", design, props: this.currentProps() });
    } else if (msg.type === "rendered") {
      this.frame.dataset.on = "1";
      this.paint();
    } else if (msg.type === "error") {
      this.el.classList.add("has-error");
      this.el.dataset.error = msg.message;
    }
  }

  setProps(props) {
    this.props = props;
    this.paint();
    this.post({ type: "props", props: this.currentProps() });
  }

  refresh() {
    this.paint();
    if (prefs.view === "live") this.post({ type: "props", props: this.currentProps() });
  }
}

addEventListener("message", (ev) => {
  for (const stage of Stage.live) {
    if (stage.frame && ev.source === stage.frame.contentWindow) {
      stage.onMessage(ev.data || {});
      return;
    }
  }
});

const cards = [];
const visible = new Set();
const observer = new IntersectionObserver(
  (entries) => {
    for (const entry of entries) {
      const card = cards.find((c) => c.stage.el === entry.target);
      if (!card) continue;
      if (entry.isIntersecting) {
        visible.add(card);
        if (prefs.view === "live") card.stage.mount();
      } else {
        visible.delete(card);
        card.stage.unmount();
      }
    }
  },
  { rootMargin: "200px 0px" },
);

function tagList(face) {
  const tags = [];
  if (!face.design) tags.push(el("span", { class: "tag", text: "watch only" }));
  else tags.push(el("span", { class: "tag", text: face.animated ? "animated" : face.clock ? "live clock" : "static" }));
  if (face.fake) tags.push(el("span", { class: "tag warn", title: face.fake, text: "simulated data" }));
  return tags;
}

function renderGallery() {
  const gallery = $("#gallery");
  const chips = $("#chips");
  for (const section of index.sections) {
    const faces = index.faces.filter((f) => f.section === section.id);
    if (!faces.length) continue;
    const grid = el("div", { class: "grid" });
    const sectionEl = el(
      "section",
      { class: "section", id: `s-${section.id}`, "aria-labelledby": `h-${section.id}` },
      el("h2", { id: `h-${section.id}` }, section.title, el("small", { text: String(faces.length) })),
      grid,
    );
    for (const face of faces) {
      const stage = new Stage(face);
      const card = el(
        "article",
        { class: "card", "data-name": face.name },
        el(
          "button",
          { class: "card-open", type: "button", "aria-label": `Open ${face.title}`, onclick: () => openDetail(face) },
          stage.el,
        ),
        el("div", { class: "card-meta" }, el("h3", { text: face.title }), el("p", { class: "tags" }, ...tagList(face))),
      );
      const entry = { face, stage, card, section: sectionEl };
      cards.push(entry);
      grid.append(card);
      stage.paint();
      observer.observe(stage.el);
    }
    gallery.append(sectionEl);
    chips.append(
      el("button", {
        type: "button",
        class: "chip",
        text: section.title,
        onclick: () => sectionEl.scrollIntoView({ behavior: "smooth", block: "start" }),
      }),
    );
  }
  $("#count").textContent = String(index.faces.length);
}

function applyFilter(query) {
  const q = query.trim().toLowerCase();
  const shown = new Map();
  for (const c of cards) {
    const hit = !q || c.face.name.toLowerCase().includes(q) || c.face.title.toLowerCase().includes(q);
    c.card.hidden = !hit;
    shown.set(c.section, (shown.get(c.section) || 0) + (hit ? 1 : 0));
  }
  for (const [section, n] of shown) section.hidden = n === 0;
}

function applyPrefs() {
  document.body.dataset.view = prefs.view;
  for (const c of cards) {
    if (prefs.view === "live" && visible.has(c)) c.stage.mount();
    if (prefs.view !== "live") c.stage.unmount();
    c.stage.refresh();
  }
  if (detail.stage) {
    if (prefs.view === "live") detail.stage.mount();
    else detail.stage.unmount();
    detail.stage.paint();
  }
  savePrefs();
}

function renderSwatches() {
  const box = $("#swatches");
  for (const color of CASE_COLORS) {
    box.append(
      el(
        "label",
        { class: "swatch", style: `--c:${color}`, title: color },
        el("input", { type: "radio", name: "caseColor", value: color, checked: color === prefs.caseColor }),
        el("span", { class: "sr", text: color }),
      ),
    );
  }
}

function bindToolbar() {
  const form = $("#toolbar");
  for (const name of ["view", "frame", "mode"]) {
    const input = form.querySelector(`input[name="${name}"][value="${prefs[name]}"]`);
    if (input) input.checked = true;
  }
  form.elements.demo.checked = prefs.demo;
  form.addEventListener("submit", (ev) => ev.preventDefault());
  form.addEventListener("change", (ev) => {
    const { name, value, checked } = ev.target;
    if (name === "speed") {
      setClock({ speed: Number(value) });
      paintSpeed();
      return;
    }
    if (name === "demo") prefs.demo = checked;
    else if (name in prefs) prefs[name] = value;
    else return;
    applyPrefs();
  });
  $("#search").addEventListener("input", (ev) => applyFilter(ev.target.value));
  $("#clock-set").addEventListener("change", (ev) => {
    const [h, m] = ev.target.value.split(":").map(Number);
    if (Number.isNaN(h) || Number.isNaN(m)) return;
    const d = new Date(virtualNow());
    d.setHours(h, m, 0, 0);
    setClock({ base: d.getTime(), anchor: Date.now() });
  });
  $("#clock-now").addEventListener("click", () => {
    form.querySelector('input[name="speed"][value="1"]').checked = true;
    $("#clock-set").value = "";
    setClock({ base: Date.now(), anchor: Date.now(), speed: 1 });
    paintSpeed();
  });
  const pill = $("#clock-pill");
  const pillSpeed = $("#pill-speed");
  const paintSpeed = () => {
    pillSpeed.textContent = clock.speed ? `${clock.speed}x` : "Pause";
  };
  pillSpeed.addEventListener("click", () => {
    const next = SPEEDS[(SPEEDS.indexOf(clock.speed) + 1) % SPEEDS.length];
    form.querySelector(`input[name="speed"][value="${next}"]`).checked = true;
    setClock({ speed: next });
    paintSpeed();
  });
  let clockInView = true;
  const showPill = () => {
    pill.hidden = clockInView || prefs.view !== "live";
  };
  new IntersectionObserver(([entry]) => {
    clockInView = entry.isIntersecting;
    showPill();
  }).observe($(".group.clock"));
  form.addEventListener("change", showPill);
  paintSpeed();
  const readouts = [$("#clock-readout"), $("#pill-readout")];
  const fmt = new Intl.DateTimeFormat("en-GB", {
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  });
  const tick = () => {
    const text = fmt.format(new Date(virtualNow())).replace(",", "");
    for (const r of readouts) r.textContent = text;
  };
  tick();
  setInterval(tick, 250);
}

const detail = { face: null, stage: null };

function propEditor(face, values, onChange) {
  const form = $("#detail-props");
  form.replaceChildren();
  for (const [key, spec] of Object.entries(face.props)) {
    const label = PROP_LABELS[key] || key;
    let control;
    if (spec.editor === "boolean") {
      control = el(
        "label",
        { class: "toggle" },
        el("input", {
          type: "checkbox",
          checked: Boolean(values[key]),
          onchange: (ev) => onChange(key, ev.target.checked),
        }),
        el("span", { text: label }),
      );
    } else if (spec.editor === "color") {
      control = el(
        "div",
        { class: "swatches", role: "radiogroup", "aria-label": label },
        ...spec.options.map((c) =>
          el(
            "label",
            { class: "swatch", style: `--c:${c}`, title: c },
            el("input", {
              type: "radio",
              name: `p-${key}`,
              value: c,
              checked: c === values[key],
              onchange: () => onChange(key, c),
            }),
            el("span", { class: "sr", text: c }),
          ),
        ),
      );
    } else if (spec.editor === "enum") {
      control = el(
        "div",
        { class: "seg", role: "radiogroup", "aria-label": label },
        ...spec.options.map((o) =>
          el(
            "label",
            {},
            el("input", {
              type: "radio",
              name: `p-${key}`,
              value: o,
              checked: String(values[key]) === String(o),
              onchange: () => onChange(key, o),
            }),
            el("span", { text: o }),
          ),
        ),
      );
    } else {
      continue;
    }
    form.append(el("div", { class: "prop" }, el("span", { class: "prop-label", text: label }), control));
  }
  form.hidden = !form.childElementCount;
}

function openDetail(face) {
  const dialog = $("#detail");
  const section = index.sections.find((s) => s.id === face.section);
  if (detail.stage) detail.stage.unmount();
  detail.face = face;
  const props = baseProps(face);
  detail.stage = new Stage(face, { props });
  $("#detail-stage").replaceChildren(detail.stage.el);
  $("#detail-section").textContent = section ? section.title : "";
  $("#detail-title").textContent = face.title;
  $("#detail-tags").replaceChildren(
    el("code", { text: face.name }),
    ...tagList(face),
    ...face.permissions.map((p) => el("span", { class: "tag", title: "Connect IQ permission", text: p })),
  );
  const note = $("#detail-note");
  note.hidden = !face.fake;
  note.textContent = face.fake ? `Simulated on the watch: ${face.fake}` : "";
  const frames = () => {
    $("#detail-awake").src = `frames/${face.name}.awake.${props.mode}.png`;
    $("#detail-asleep").src = `frames/${face.name}.asleep.${props.mode}.png`;
  };
  propEditor(face, props, (key, value) => {
    props[key] = value;
    detail.stage.setProps({ ...props });
    if (key === "mode") frames();
  });
  frames();
  $("#detail-ref").src = `refs/${face.name}.png`;
  $("#detail-ref").alt = `${face.title}: design rendered at 1 bit`;
  $("#detail-awake").alt = `${face.title}: watch build, awake`;
  $("#detail-asleep").alt = `${face.title}: watch build, asleep`;
  const actions = $("#detail-actions");
  actions.replaceChildren();
  if (index.repo) {
    const gh = `https://github.com/${index.repo}`;
    actions.append(
      el("a", {
        class: "button",
        href: `${gh}/releases/latest/download/${face.name}.prg`,
        text: `Download ${face.name}.prg`,
      }),
      el("a", { class: "ghost", href: `${gh}/tree/main/faces/${face.name}`, text: "Source" }),
    );
    if (face.design) {
      actions.append(el("a", { class: "ghost", href: `${gh}/blob/main/design/${face.name}.dc.html`, text: "Design" }));
    }
  }
  detail.stage.paint();
  if (prefs.view === "live") detail.stage.mount();
  history.replaceState(null, "", `#face=${encodeURIComponent(face.name)}`);
  if (!dialog.open) dialog.showModal();
}

function stepDetail(delta) {
  const list = cards.filter((c) => !c.card.hidden).map((c) => c.face);
  const i = list.indexOf(detail.face);
  if (i < 0 || !list.length) return;
  openDetail(list[(i + delta + list.length) % list.length]);
}

function bindDetail() {
  const dialog = $("#detail");
  $("#detail-close").addEventListener("click", () => dialog.close());
  $("#detail-prev").addEventListener("click", () => stepDetail(-1));
  $("#detail-next").addEventListener("click", () => stepDetail(1));
  dialog.addEventListener("click", (ev) => {
    if (ev.target === dialog) dialog.close();
  });
  dialog.addEventListener("keydown", (ev) => {
    if (ev.target.closest("input, select, textarea")) return;
    if (ev.key === "ArrowLeft") stepDetail(-1);
    if (ev.key === "ArrowRight") stepDetail(1);
  });
  dialog.addEventListener("close", () => {
    if (detail.stage) detail.stage.unmount();
    detail.stage = null;
    detail.face = null;
    history.replaceState(null, "", location.pathname + location.search);
  });
}

function bindLinks() {
  const links = { "#link-repo": "", "#link-releases": "/releases/latest", "#link-install": "#install" };
  for (const [sel, suffix] of Object.entries(links)) {
    const a = $(sel);
    if (index.repo) a.href = `https://github.com/${index.repo}${suffix}`;
    else a.hidden = true;
  }
  const license = $("#link-license");
  if (index.repo) license.href = `https://github.com/${index.repo}/blob/main/LICENSE`;
}

async function main() {
  const [data, code] = await Promise.all([fetch("faces.json"), fetch("frame.js")]);
  index = await data.json();
  runtime = (await code.text()).replace(/<\/script/gi, "<\\/script");
  renderSwatches();
  bindToolbar();
  bindDetail();
  bindLinks();
  renderGallery();
  applyPrefs();
  const m = location.hash.match(/^#face=(.+)$/);
  const face = m && index.faces.find((f) => f.name === decodeURIComponent(m[1]));
  if (face) openDetail(face);
}

main();
