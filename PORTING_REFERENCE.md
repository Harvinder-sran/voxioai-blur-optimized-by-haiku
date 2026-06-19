# VoxioAI Website — Exact Porting Reference

**For:** An agent applying all 10 changes to a copy of this codebase that was made at the point of the initial commit (`a44be01`).

**Files you will edit:**
- `index.html` — main site file (Changes 2, 3⁽ᵛᵉʳᶜᵉˡ⁾, 4, 5, 7, 9, 10)
- `scene-no-ripple.json` — Unicorn Studio scene (Changes 1, 6, 8)
- `vercel.json` — deployment config (Change 3)

**Golden rule:** Never open `index.html` via `file://`. Always use `python -m http.server 3000` and open `http://localhost:3000`.

---

## CHANGE 1 — Progressive blur optimised (scene-no-ripple.json)

**Context:** The `progressiveBlur` layer in the scene JSON has a compiled GLSL fragment shader. The blur strength multipliers were reduced by ~30% to ease render cost. This was applied before the first commit — so if your copy of `scene-no-ripple.json` matches the initial commit, these values are already correct. Verify by searching for the pattern below.

**How to find it:** Open `scene-no-ripple.json` (it is a single minified line). Search for `"type":"progressiveBlur"`. Inside that layer object, search for `compiledFragmentShaders`. Inside the GLSL string, find the two blur multipliers.

The exact surrounding context to locate them:

```
"type":"progressiveBlur"
```
Within that layer's compiled shader, the blur multiplier appears as a float multiplied against a step size. Original AURA values were `6.0` and `11.0`. The optimised values (already in the initial commit) are:

| Was (AURA original) | Now (optimised) |
|---------------------|-----------------|
| `6.0` (or `6`)      | `4.0` (or `4`)  |
| `11.0` (or `11`)    | `8.0` (or `8`)  |

**If your copy already matches the initial commit, skip this change.** The file is correct. If you're starting from the raw AURA scene JSON (not the cleaned `scene-no-ripple.json`), use the `scene-no-ripple.json` from this repo directly instead of trying to reconstruct it.

---

## CHANGE 2 — Blue animation moved to bottom-right; glow default shifted (index.html)

**Context:** The CSS flow-field background (5 floating blue layers driven by rAF) was originally centred in the upper area. Moved all 5 layers to the lower-right quadrant. Also shifted the glow's idle default position.

**How to find it:** In `index.html`, near the bottom inside the first `<script>` block. Look for the comment:
```
// Each layer: center (cx,cy in %), size (vw), blur (px), color, stretch (ex,ey),
```

### 2A — The `var defs` layer array

**BEFORE:**
```js
var defs = [
  { cx:56, cy:10, size:46, blur:60, color:'rgba(37,99,235,0.50)',  ex:1.55, ey:0.80, ax:9,  ay:7,  f:[0.17,0.26,0.21,0.13], ph:[0.0,1.3,2.1,0.7], rot:14, depth:9 },
  { cx:90, cy:0,  size:42, blur:62, color:'rgba(56,189,248,0.46)', ex:1.30, ey:0.95, ax:7,  ay:6,  f:[0.13,0.23,0.16,0.29], ph:[1.1,0.2,2.7,1.6], rot:10, depth:15 },
  { cx:42, cy:34, size:36, blur:58, color:'rgba(59,130,246,0.42)', ex:1.40, ey:0.85, ax:11, ay:8,  f:[0.21,0.15,0.27,0.18], ph:[2.4,1.7,0.5,2.0], rot:18, depth:7  },
  { cx:68, cy:16, size:24, blur:38, color:'rgba(96,165,250,0.55)', ex:1.60, ey:0.70, ax:12, ay:9,  f:[0.29,0.19,0.33,0.24], ph:[0.6,2.2,1.1,0.3], rot:24, depth:20 },
  { cx:74, cy:26, size:16, blur:26, color:'rgba(29,78,216,0.45)',  ex:1.20, ey:0.90, ax:10, ay:10, f:[0.34,0.28,0.22,0.37], ph:[1.9,0.9,2.5,1.2], rot:30, depth:26 }
];
```

**AFTER:**
```js
var defs = [
  { cx:78, cy:72, size:46, blur:60, color:'rgba(37,99,235,0.50)',  ex:1.55, ey:0.80, ax:9,  ay:7,  f:[0.17,0.26,0.21,0.13], ph:[0.0,1.3,2.1,0.7], rot:14, depth:9 },
  { cx:92, cy:75, size:42, blur:62, color:'rgba(56,189,248,0.46)', ex:1.30, ey:0.95, ax:7,  ay:6,  f:[0.13,0.23,0.16,0.29], ph:[1.1,0.2,2.7,1.6], rot:10, depth:15 },
  { cx:85, cy:78, size:36, blur:58, color:'rgba(59,130,246,0.42)', ex:1.40, ey:0.85, ax:11, ay:8,  f:[0.21,0.15,0.27,0.18], ph:[2.4,1.7,0.5,2.0], rot:18, depth:7  },
  { cx:88, cy:70, size:24, blur:38, color:'rgba(96,165,250,0.55)', ex:1.60, ey:0.70, ax:12, ay:9,  f:[0.29,0.19,0.33,0.24], ph:[0.6,2.2,1.1,0.3], rot:24, depth:20 },
  { cx:90, cy:82, size:16, blur:26, color:'rgba(29,78,216,0.45)',  ex:1.20, ey:0.90, ax:10, ay:10, f:[0.34,0.28,0.22,0.37], ph:[1.9,0.9,2.5,1.2], rot:30, depth:26 }
];
```

### 2B — Pointer/glow default position

**BEFORE:**
```js
var p = { nx:0, ny:0, tnx:0, tny:0, cx:0.7, cy:0.25, tcx:0.7, tcy:0.25, active:0, tactive:0 };
```

**AFTER:**
```js
var p = { nx:0, ny:0, tnx:0, tny:0, cx:0.85, cy:0.80, tcx:0.85, tcy:0.80, active:0, tactive:0 };
```

---

## CHANGE 3 — Remove deprecated `name` from vercel.json

**How to find it:** Open `vercel.json`. It is a small file.

**BEFORE:**
```json
{
  "name": "voxioai-website",
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

**AFTER:**
```json
{
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

*(The exact `rewrites` array content may vary — only remove the `"name"` line.)*

---

## CHANGE 4 — Nav mobile sizing + Recording cards refactor (index.html)

This commit did two things. Apply both.

### 4A — Nav: smaller mobile padding and icon sizes

**How to find it:** The `<header>` at the top of `<body>`, specifically the `<nav>` and its logo block.

**BEFORE — `<nav>` opening and inner wrapper:**
```html
<nav class="max-w-6xl mx-auto px-4 sm:px-6 pt-4">
  <div class="relative overflow-hidden rounded-full bg-white/84 backdrop-blur-2xl border border-white/90 shadow-[0_14px_38px_-22px_rgba(15,23,42,0.42),inset_0_1px_0_rgba(255,255,255,1)] px-3 sm:px-4 py-2.5 sm:py-3">
    <div class="relative z-10 flex items-center justify-between gap-3">
      <a href="#top" class="flex items-center gap-2.5 group">
        <span class="w-9 h-9 rounded-full bg-gradient-to-b from-white to-slate-100 border border-slate-200 shadow-[0_2px_8px_rgba(15,23,42,0.06),inset_0_1px_0_white] flex items-center justify-center text-blue-600">
          <iconify-icon icon="solar:microphone-3-bold" class="text-lg"></iconify-icon>
        </span>
```

**AFTER — `<nav>` opening and inner wrapper:**
```html
<nav class="max-w-6xl mx-auto px-2 sm:px-6 pt-2 sm:pt-4">
  <div class="relative overflow-hidden rounded-full bg-white/84 backdrop-blur-2xl border border-white/90 shadow-[0_14px_38px_-22px_rgba(15,23,42,0.42),inset_0_1px_0_rgba(255,255,255,1)] px-2 sm:px-4 py-1.5 sm:py-3">
    <div class="relative z-10 flex items-center justify-between gap-2 sm:gap-3">
      <a href="#top" class="flex items-center gap-1.5 sm:gap-2.5 group">
        <span class="w-7 sm:w-9 h-7 sm:h-9 rounded-full bg-gradient-to-b from-white to-slate-100 border border-slate-200 shadow-[0_2px_8px_rgba(15,23,42,0.06),inset_0_1px_0_white] flex items-center justify-center text-blue-600 shrink-0">
          <iconify-icon icon="solar:microphone-3-bold" class="text-base sm:text-lg"></iconify-icon>
        </span>
```

**BEFORE — Nav "Book a call" button + hamburger:**
```html
<div class="flex items-center gap-2">
  <a href="#book" class="inline-flex items-center justify-center rounded-full px-4 py-2 text-xs text-white bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 shadow-[0_5px_14px_rgba(59,130,246,0.28),inset_0_1px_0_rgba(255,255,255,0.35)] hover:-translate-y-0.5 transition-all">Book a call</a>
  <button id="navToggle" aria-label="Menu" class="md:hidden w-9 h-9 rounded-full bg-white/78 border border-slate-200 shadow-[inset_0_1px_0_white] flex items-center justify-center text-slate-600"><iconify-icon icon="solar:hamburger-menu-linear" class="text-lg"></iconify-icon></button>
</div>
```

**AFTER — Nav "Book a call" button + hamburger:**
```html
<div class="flex items-center gap-1.5 sm:gap-2">
  <a href="#book" class="inline-flex items-center justify-center rounded-full px-2.5 sm:px-4 py-1.5 sm:py-2 text-[11px] sm:text-xs text-white bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 shadow-[0_5px_14px_rgba(59,130,246,0.28),inset_0_1px_0_rgba(255,255,255,0.35)] hover:-translate-y-0.5 transition-all whitespace-nowrap">Book a call</a>
  <button id="navToggle" aria-label="Menu" class="md:hidden w-7 sm:w-9 h-7 sm:h-9 rounded-full bg-white/78 border border-slate-200 shadow-[inset_0_1px_0_white] flex items-center justify-center text-slate-600 shrink-0"><iconify-icon icon="solar:hamburger-menu-linear" class="text-base sm:text-lg"></iconify-icon></button>
</div>
```

### 4B — Recording cards: remove badges, move duration to header

The 4 recording cards in the `#work` section each had a coloured category badge (Sales / Collections / Outbound / Support) and duration at the bottom next to the waveform. Replace ALL 4 cards.

**BEFORE — Recording 1:**
```html
<article class="rounded-[1.75rem] bg-white/72 border border-white p-4 sm:p-5 shadow-[0_14px_34px_-26px_rgba(15,23,42,0.32),inset_0_1px_0_white]">
  <div class="flex items-start justify-between gap-3">
    <div class="min-w-0"><h3 class="text-sm font-medium text-slate-900 truncate">Inbound booking — dental clinic</h3><p class="text-xs text-slate-400 font-light mt-0.5">Reception agent · English</p></div>
    <span class="shrink-0 inline-flex items-center gap-1.5 rounded-full bg-blue-50 border border-blue-100 px-2.5 py-1 text-[11px] font-medium text-blue-600"><span class="w-1.5 h-1.5 rounded-full bg-blue-500"></span>Sales</span>
  </div>
  <div class="mt-4 flex items-center gap-3">
    <button data-play class="shrink-0 w-12 h-12 rounded-full bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white shadow-[0_8px_20px_-6px_rgba(59,130,246,0.5),inset_0_1px_0_rgba(255,255,255,0.35)] flex items-center justify-center active:scale-95 transition"><iconify-icon data-icon icon="solar:play-bold" class="text-xl translate-x-[1px]"></iconify-icon></button>
    <div class="vx-wave flex-1" data-wave data-bars="40"></div>
    <span class="mono text-[11px] text-slate-400 shrink-0 w-10 text-right">0:48</span>
  </div>
</article>
```

**AFTER — Recording 1:**
```html
<article class="rounded-[1.75rem] bg-white/72 border border-white p-4 sm:p-5 shadow-[0_14px_34px_-26px_rgba(15,23,42,0.32),inset_0_1px_0_white]">
  <div class="flex items-start justify-between gap-2">
    <h3 class="text-sm font-medium text-slate-900">Inbound booking — dental clinic</h3>
    <span class="mono text-[11px] text-slate-400 shrink-0">0:48</span>
  </div>
  <div class="mt-4 flex items-center gap-3">
    <button data-play class="shrink-0 w-12 h-12 rounded-full bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white shadow-[0_8px_20px_-6px_rgba(59,130,246,0.5),inset_0_1px_0_rgba(255,255,255,0.35)] flex items-center justify-center active:scale-95 transition"><iconify-icon data-icon icon="solar:play-bold" class="text-xl translate-x-[1px]"></iconify-icon></button>
    <div class="vx-wave flex-1" data-wave data-bars="40"></div>
  </div>
</article>
```

**BEFORE — Recording 2:**
```html
<article class="rounded-[1.75rem] bg-white/72 border border-white p-4 sm:p-5 shadow-[0_14px_34px_-26px_rgba(15,23,42,0.32),inset_0_1px_0_white]">
  <div class="flex items-start justify-between gap-3">
    <div class="min-w-0"><h3 class="text-sm font-medium text-slate-900 truncate">Collections reminder — fintech</h3><p class="text-xs text-slate-400 font-light mt-0.5">Outbound agent · Hindi + English</p></div>
    <span class="shrink-0 inline-flex items-center gap-1.5 rounded-full bg-amber-50 border border-amber-100 px-2.5 py-1 text-[11px] font-medium text-amber-600"><span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>Collections</span>
  </div>
  <div class="mt-4 flex items-center gap-3">
    <button data-play class="shrink-0 w-12 h-12 rounded-full bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white shadow-[0_8px_20px_-6px_rgba(59,130,246,0.5),inset_0_1px_0_rgba(255,255,255,0.35)] flex items-center justify-center active:scale-95 transition"><iconify-icon data-icon icon="solar:play-bold" class="text-xl translate-x-[1px]"></iconify-icon></button>
    <div class="vx-wave flex-1" data-wave data-bars="40"></div>
    <span class="mono text-[11px] text-slate-400 shrink-0 w-10 text-right">1:12</span>
  </div>
</article>
```

**AFTER — Recording 2:**
```html
<article class="rounded-[1.75rem] bg-white/72 border border-white p-4 sm:p-5 shadow-[0_14px_34px_-26px_rgba(15,23,42,0.32),inset_0_1px_0_white]">
  <div class="flex items-start justify-between gap-2">
    <h3 class="text-sm font-medium text-slate-900">Collections reminder — fintech</h3>
    <span class="mono text-[11px] text-slate-400 shrink-0">1:12</span>
  </div>
  <div class="mt-4 flex items-center gap-3">
    <button data-play class="shrink-0 w-12 h-12 rounded-full bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white shadow-[0_8px_20px_-6px_rgba(59,130,246,0.5),inset_0_1px_0_rgba(255,255,255,0.35)] flex items-center justify-center active:scale-95 transition"><iconify-icon data-icon icon="solar:play-bold" class="text-xl translate-x-[1px]"></iconify-icon></button>
    <div class="vx-wave flex-1" data-wave data-bars="40"></div>
  </div>
</article>
```

**BEFORE — Recording 3:**
```html
<article class="rounded-[1.75rem] bg-white/72 border border-white p-4 sm:p-5 shadow-[0_14px_34px_-26px_rgba(15,23,42,0.32),inset_0_1px_0_white]">
  <div class="flex items-start justify-between gap-3">
    <div class="min-w-0"><h3 class="text-sm font-medium text-slate-900 truncate">Outbound follow-up — solar leads</h3><p class="text-xs text-slate-400 font-light mt-0.5">Sales agent · English</p></div>
    <span class="shrink-0 inline-flex items-center gap-1.5 rounded-full bg-sky-50 border border-sky-100 px-2.5 py-1 text-[11px] font-medium text-sky-600"><span class="w-1.5 h-1.5 rounded-full bg-sky-500"></span>Outbound</span>
  </div>
  <div class="mt-4 flex items-center gap-3">
    <button data-play class="shrink-0 w-12 h-12 rounded-full bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white shadow-[0_8px_20px_-6px_rgba(59,130,246,0.5),inset_0_1px_0_rgba(255,255,255,0.35)] flex items-center justify-center active:scale-95 transition"><iconify-icon data-icon icon="solar:play-bold" class="text-xl translate-x-[1px]"></iconify-icon></button>
    <div class="vx-wave flex-1" data-wave data-bars="40"></div>
    <span class="mono text-[11px] text-slate-400 shrink-0 w-10 text-right">0:54</span>
  </div>
</article>
```

**AFTER — Recording 3:**
```html
<article class="rounded-[1.75rem] bg-white/72 border border-white p-4 sm:p-5 shadow-[0_14px_34px_-26px_rgba(15,23,42,0.32),inset_0_1px_0_white]">
  <div class="flex items-start justify-between gap-2">
    <h3 class="text-sm font-medium text-slate-900">Outbound follow-up — solar leads</h3>
    <span class="mono text-[11px] text-slate-400 shrink-0">0:54</span>
  </div>
  <div class="mt-4 flex items-center gap-3">
    <button data-play class="shrink-0 w-12 h-12 rounded-full bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white shadow-[0_8px_20px_-6px_rgba(59,130,246,0.5),inset_0_1px_0_rgba(255,255,255,0.35)] flex items-center justify-center active:scale-95 transition"><iconify-icon data-icon icon="solar:play-bold" class="text-xl translate-x-[1px]"></iconify-icon></button>
    <div class="vx-wave flex-1" data-wave data-bars="40"></div>
  </div>
</article>
```

**BEFORE — Recording 4:**
```html
<article class="rounded-[1.75rem] bg-white/72 border border-white p-4 sm:p-5 shadow-[0_14px_34px_-26px_rgba(15,23,42,0.32),inset_0_1px_0_white]">
  <div class="flex items-start justify-between gap-3">
    <div class="min-w-0"><h3 class="text-sm font-medium text-slate-900 truncate">Support triage — SaaS helpdesk</h3><p class="text-xs text-slate-400 font-light mt-0.5">Support agent · English</p></div>
    <span class="shrink-0 inline-flex items-center gap-1.5 rounded-full bg-emerald-50 border border-emerald-100 px-2.5 py-1 text-[11px] font-medium text-emerald-600"><span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>Support</span>
  </div>
  <div class="mt-4 flex items-center gap-3">
    <button data-play class="shrink-0 w-12 h-12 rounded-full bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white shadow-[0_8px_20px_-6px_rgba(59,130,246,0.5),inset_0_1px_0_rgba(255,255,255,0.35)] flex items-center justify-center active:scale-95 transition"><iconify-icon data-icon icon="solar:play-bold" class="text-xl translate-x-[1px]"></iconify-icon></button>
    <div class="vx-wave flex-1" data-wave data-bars="40"></div>
    <span class="mono text-[11px] text-slate-400 shrink-0 w-10 text-right">1:31</span>
  </div>
</article>
```

**AFTER — Recording 4:**
```html
<article class="rounded-[1.75rem] bg-white/72 border border-white p-4 sm:p-5 shadow-[0_14px_34px_-26px_rgba(15,23,42,0.32),inset_0_1px_0_white]">
  <div class="flex items-start justify-between gap-2">
    <h3 class="text-sm font-medium text-slate-900">Support triage — SaaS helpdesk</h3>
    <span class="mono text-[11px] text-slate-400 shrink-0">1:31</span>
  </div>
  <div class="mt-4 flex items-center gap-3">
    <button data-play class="shrink-0 w-12 h-12 rounded-full bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white shadow-[0_8px_20px_-6px_rgba(59,130,246,0.5),inset_0_1px_0_rgba(255,255,255,0.35)] flex items-center justify-center active:scale-95 transition"><iconify-icon data-icon icon="solar:play-bold" class="text-xl translate-x-[1px]"></iconify-icon></button>
    <div class="vx-wave flex-1" data-wave data-bars="40"></div>
  </div>
</article>
```

---

## CHANGE 5 — Agent descriptions added back to recording cards (index.html)

**Context:** After Change 4 removed the badges, the subtitle text was also lost from the header. This change re-adds it as a plain `<p>` beneath each title, wrapped in `<div class="min-w-0">`.

**How to find it:** Each recording card's header `<div>` — the one you just edited in Change 4.

Apply to all 4 cards. The pattern is identical for each — just swap in the correct subtitle.

**BEFORE — each card header (example: Recording 1 after Change 4):**
```html
<div class="flex items-start justify-between gap-2">
  <h3 class="text-sm font-medium text-slate-900">Inbound booking — dental clinic</h3>
  <span class="mono text-[11px] text-slate-400 shrink-0">0:48</span>
</div>
```

**AFTER — wrap h3 in div and add subtitle `<p>`:**
```html
<div class="flex items-start justify-between gap-2">
  <div class="min-w-0">
    <h3 class="text-sm font-medium text-slate-900">Inbound booking — dental clinic</h3>
    <p class="text-xs text-slate-400 font-light mt-0.5">Reception agent · English</p>
  </div>
  <span class="mono text-[11px] text-slate-400 shrink-0">0:48</span>
</div>
```

**Subtitles for each card:**

| Card title | Subtitle |
|------------|----------|
| Inbound booking — dental clinic | `Reception agent · English` |
| Collections reminder — fintech | `Outbound agent · Hindi + English` |
| Outbound follow-up — solar leads | `Sales agent · English` |
| Support triage — SaaS helpdesk | `Support agent · English` |

---

## CHANGE 6 — flowField Y position: 0.5 → 0.8 (scene-no-ripple.json)

**Context:** `scene-no-ripple.json` is a single minified JSON line. The `flowField` layer contains a compiled GLSL fragment shader. Inside that shader, the animation's default Y centre is set by `vec2(0.5, Y)` in the `mPos` calculation inside the `flow()` function.

**How to find it:** Open `scene-no-ripple.json`. Search for exactly:
```
vec2 mPos = vec2(0.5, 0.5) + mix(vec2(0), (uMousePos-0.5), 0.1000)
```

**BEFORE (exact substring):**
```
vec2 mPos = vec2(0.5, 0.5) + mix(vec2(0), (uMousePos-0.5), 0.1000)
```

**AFTER (exact substring):**
```
vec2 mPos = vec2(0.5, 0.8) + mix(vec2(0), (uMousePos-0.5), 0.1000)
```

Change `0.5` → `0.8` (the second argument inside `vec2(0.5, ___)` only — the first `0.5` is the X axis and must not change).

---

## CHANGE 7 — Remove "Voice AI Agency" from nav and hero (index.html)

Two places. Apply both.

### 7A — Nav logo: remove "Voice AI Agency" tagline

**How to find it:** Inside `<header>`, the logo `<a href="#top">` block. The logo currently wraps `VoxioAI` and a tagline in a `<span class="flex flex-col">`.

**BEFORE:**
```html
<a href="#top" class="flex items-center gap-1.5 sm:gap-2.5 group">
  <span class="w-7 sm:w-9 h-7 sm:h-9 rounded-full bg-gradient-to-b from-white to-slate-100 border border-slate-200 shadow-[0_2px_8px_rgba(15,23,42,0.06),inset_0_1px_0_white] flex items-center justify-center text-blue-600 shrink-0">
    <iconify-icon icon="solar:microphone-3-bold" class="text-base sm:text-lg"></iconify-icon>
  </span>
  <span class="flex flex-col leading-none">
    <span class="mono text-xs sm:text-sm font-semibold tracking-[-0.08em] text-slate-950 group-hover:text-blue-600 transition-colors">VoxioAI</span>
    <span class="hidden md:block mt-0.5 text-[10px] font-light tracking-[-0.03em] text-slate-400">Voice AI Agency</span>
  </span>
</a>
```

**AFTER:**
```html
<a href="#top" class="flex items-center gap-1.5 sm:gap-2.5 group">
  <span class="w-7 sm:w-9 h-7 sm:h-9 rounded-full bg-gradient-to-b from-white to-slate-100 border border-slate-200 shadow-[0_2px_8px_rgba(15,23,42,0.06),inset_0_1px_0_white] flex items-center justify-center text-blue-600 shrink-0">
    <iconify-icon icon="solar:microphone-3-bold" class="text-base sm:text-lg"></iconify-icon>
  </span>
  <span class="mono text-xs sm:text-sm font-semibold tracking-[-0.08em] text-slate-950 group-hover:text-blue-600 transition-colors">VoxioAI</span>
</a>
```

### 7B — Hero: remove "VOICE AI AGENCY" chip above the h1

**How to find it:** In the hero `<!-- Copy -->` column, just before `<h1`. There is a pill chip div.

**BEFORE (delete this entire block):**
```html
<div class="inline-flex items-center gap-2 rounded-full bg-white/75 border border-white px-3.5 py-2 shadow-[0_6px_18px_-12px_rgba(15,23,42,0.3),inset_0_1px_0_white] mb-7">
  <span class="w-7 h-7 rounded-full bg-gradient-to-b from-blue-50 to-white border border-blue-100 shadow-[inset_0_1px_0_white] flex items-center justify-center">
    <iconify-icon icon="solar:microphone-3-linear" style="stroke-width:1.5;" class="text-base text-blue-500"></iconify-icon>
  </span>
  <span class="mono text-xs font-medium tracking-[-0.04em] text-slate-500">VOICE AI AGENCY</span>
</div>
```

**AFTER:** Delete the entire block above. The `<h1>` becomes the first child of the copy `<div>`.

---

## CHANGE 8 — flowField Y position: 0.8 → 0.1 (scene-no-ripple.json)

**Context:** Same location as Change 6. After Change 6 the value is `0.8`; this change moves it to `0.1` (higher on screen).

**How to find it:** Search for the string you set in Change 6:
```
vec2 mPos = vec2(0.5, 0.8) + mix(vec2(0), (uMousePos-0.5), 0.1000)
```

**BEFORE (exact substring — after Change 6):**
```
vec2 mPos = vec2(0.5, 0.8) + mix(vec2(0), (uMousePos-0.5), 0.1000)
```

**AFTER (exact substring):**
```
vec2 mPos = vec2(0.5, 0.1) + mix(vec2(0), (uMousePos-0.5), 0.1000)
```

> **Shortcut:** If applying both Changes 6 and 8 together (net effect), just change `vec2(0.5, 0.5)` to `vec2(0.5, 0.1)` in one step.

---

## CHANGE 9 — Hero panel: fake chat → live "Call me now" form (index.html)

### 9A — Add modal animation CSS to `<style>` block

**How to find it:** The `<style>` tag in `<head>`. Find the last rule inside it (the `@media (prefers-reduced-motion)` block). Add the following **after** the closing brace of that rule, just before `</style>`:

**ADD (new CSS — does not replace anything):**
```css
/* Demo call modal */
@keyframes vxModalIn{from{opacity:0;transform:scale(0.96) translateY(10px)}to{opacity:1;transform:scale(1) translateY(0)}}
.vx-modal-card{animation:vxModalIn .22s cubic-bezier(.22,1,.36,1)}
@keyframes vxBdIn{from{opacity:0}to{opacity:1}}
.vx-modal-bd{animation:vxBdIn .18s ease}
```

### 9B — Replace hero right panel inner content

**How to find it:** The hero section has a two-column grid. The right column is the "Hero call panel". Inside the outer card wrapper, there is an inner rounded card containing a header row and a chat transcript. Replace the header text and the entire chat body.

**BEFORE — inner card (header + chat messages):**
```html
<div class="rounded-[1.5rem] bg-gradient-to-b from-white to-slate-50 border border-slate-200 shadow-[inset_0_1px_0_white] overflow-hidden">
  <div class="px-4 sm:px-5 py-3.5 flex items-center justify-between border-b border-slate-200/80">
    <div class="flex items-center gap-2">
      <span class="w-2 h-2 rounded-full bg-emerald-500 vx-pulse"></span>
      <span class="text-xs text-slate-600">Live call · 00:48</span>
    </div>
    <span class="mono text-[11px] text-slate-400 tracking-[-0.05em]">VOXIO AGENT</span>
  </div>
  <div class="p-4 sm:p-5 space-y-3">
    <div class="flex justify-start">
      <div class="max-w-[82%] rounded-2xl rounded-tl-md bg-white border border-slate-200 px-3.5 py-2.5 shadow-[0_2px_8px_rgba(15,23,42,0.03)]">
        <p class="text-[13px] leading-5 text-slate-700">Thanks for calling Brightsmile Dental — would you like to book or reschedule?</p>
      </div>
    </div>
    <div class="flex justify-end">
      <div class="max-w-[82%] rounded-2xl rounded-tr-md bg-gradient-to-b from-blue-500 to-blue-600 text-white px-3.5 py-2.5 shadow-[0_8px_20px_-10px_rgba(59,130,246,0.6),inset_0_1px_0_rgba(255,255,255,0.3)]">
        <p class="text-[13px] leading-5">Book a cleaning, Thursday afternoon if you have it.</p>
      </div>
    </div>
    <div class="flex justify-start">
      <div class="max-w-[82%] rounded-2xl rounded-tl-md bg-white border border-slate-200 px-3.5 py-2.5 shadow-[0_2px_8px_rgba(15,23,42,0.03)]">
        <p class="text-[13px] leading-5 text-slate-700">I have 2:30 or 4:00 PM open on Thursday. Which works best?</p>
      </div>
    </div>
    <div class="mt-1 flex items-center gap-3 rounded-2xl bg-blue-50/70 border border-blue-100 px-3.5 py-2.5">
      <iconify-icon icon="solar:calendar-mark-linear" style="stroke-width:1.5;" class="text-lg text-blue-500 shrink-0"></iconify-icon>
      <span class="text-xs text-slate-600 flex-1">Booking appointment…</span>
      <div class="vx-wave is-playing w-16" data-wave data-bars="14"></div>
    </div>
  </div>
</div>
```

**AFTER — inner card (header + demo form):**
```html
<div class="rounded-[1.5rem] bg-gradient-to-b from-white to-slate-50 border border-slate-200 shadow-[inset_0_1px_0_white] overflow-hidden">
  <div class="px-4 sm:px-5 py-3.5 flex items-center justify-between border-b border-slate-200/80">
    <div class="flex items-center gap-2">
      <span class="w-2 h-2 rounded-full bg-emerald-500 vx-pulse"></span>
      <span class="text-xs text-slate-600">Hear a live agent — on your phone</span>
    </div>
    <span class="mono text-[11px] text-slate-400 tracking-[-0.05em]">VOXIO AGENT</span>
  </div>
  <div class="p-4 sm:p-5">
    <!-- "Call me now" demo form -->
    <form id="demoForm" novalidate class="space-y-3">
      <input id="d-name" name="name" required placeholder="Your name" autocomplete="name"
        class="w-full rounded-xl bg-white border border-slate-200 px-3.5 py-2.5 text-sm text-slate-800 placeholder:text-slate-400 shadow-[inset_0_1px_2px_rgba(15,23,42,0.04)] focus:outline-none focus:ring-2 focus:ring-blue-400/40 focus:border-blue-300 transition" />
      <input id="d-email" name="email" type="email" required placeholder="Email address" autocomplete="email"
        class="w-full rounded-xl bg-white border border-slate-200 px-3.5 py-2.5 text-sm text-slate-800 placeholder:text-slate-400 shadow-[inset_0_1px_2px_rgba(15,23,42,0.04)] focus:outline-none focus:ring-2 focus:ring-blue-400/40 focus:border-blue-300 transition" />
      <div class="flex items-center gap-2">
        <span class="inline-flex items-center gap-1 rounded-xl bg-slate-50 border border-slate-200 px-3 py-2.5 text-sm text-slate-500 shrink-0 shadow-[inset_0_1px_2px_rgba(15,23,42,0.04)] select-none">🇮🇳 +91</span>
        <input id="d-phone" name="phone" inputmode="numeric" required placeholder="10-digit number" autocomplete="tel"
          class="flex-1 min-w-0 rounded-xl bg-white border border-slate-200 px-3.5 py-2.5 text-sm text-slate-800 placeholder:text-slate-400 shadow-[inset_0_1px_2px_rgba(15,23,42,0.04)] focus:outline-none focus:ring-2 focus:ring-blue-400/40 focus:border-blue-300 transition" />
      </div>
      <p id="d-error" class="hidden text-red-500 text-xs px-1 leading-4"></p>
      <button id="d-submit" type="submit"
        class="w-full inline-flex items-center justify-center gap-2 rounded-full px-6 py-3 bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white text-sm font-medium shadow-[0_10px_24px_rgba(59,130,246,0.26),inset_0_1px_0_rgba(255,255,255,0.35)] hover:from-blue-400 hover:to-blue-500 hover:-translate-y-0.5 active:shadow-[inset_0_2px_4px_rgba(0,0,0,0.18)] transition-all disabled:opacity-60 disabled:cursor-not-allowed disabled:translate-y-0">
        <iconify-icon icon="solar:phone-calling-rounded-bold" class="text-lg"></iconify-icon>
        <span id="d-label">Call me now</span>
      </button>
      <p class="text-[11px] text-slate-400 font-light text-center leading-4">We'll call within ~10 seconds · 1 demo per number</p>
    </form>
    <!-- Success state (hidden until call dispatched) -->
    <div id="demoSuccess" class="hidden text-center py-5 space-y-3">
      <div class="w-14 h-14 mx-auto rounded-full bg-emerald-50 border border-emerald-100 flex items-center justify-center">
        <iconify-icon icon="solar:phone-calling-rounded-bold" class="text-2xl text-emerald-500"></iconify-icon>
      </div>
      <p class="text-base font-medium text-slate-900">Calling you now</p>
      <p id="demoSuccessNum" class="text-sm text-slate-500 font-light">Keep your phone handy.</p>
      <a href="https://calendly.com/harvindersran101/intro-call" target="_blank" rel="noopener"
        class="inline-flex items-center gap-1.5 text-xs text-blue-500 hover:text-blue-600 transition-colors">Book a full demo <iconify-icon icon="solar:arrow-right-linear" class="text-sm"></iconify-icon></a>
    </div>
  </div>
</div>
```

### 9C — Add hero form JavaScript

**How to find it:** Before the closing `</body>` tag. Add this as a new `<script>` block.

**ADD (new script block — does not replace anything):**
```html
<script>
  // ---- "Call me now" hero demo form ----
  (function () {
    var ENDPOINT = 'https://api.voxioai.com/api/demo-call';
    var form   = document.getElementById('demoForm');
    var errEl  = document.getElementById('d-error');
    var btn    = document.getElementById('d-submit');
    var label  = document.getElementById('d-label');
    if (!form) return;
    function showErr(m) { errEl.textContent = m; errEl.classList.remove('hidden'); }
    form.addEventListener('submit', async function (e) {
      e.preventDefault();
      errEl.classList.add('hidden');
      var name   = document.getElementById('d-name').value.trim();
      var email  = document.getElementById('d-email').value.trim();
      var digits = document.getElementById('d-phone').value.replace(/\D/g, '');
      if (name.length < 2)               return showErr('Please enter your name.');
      if (!/^\S+@\S+\.\S+$/.test(email)) return showErr('Please enter a valid email.');
      if (digits.length !== 10)          return showErr('Enter a 10-digit Indian mobile number.');
      var phone = '+91' + digits;
      btn.disabled = true;
      label.textContent = 'Connecting…';
      try {
        var res = await fetch(ENDPOINT, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name: name, email: email, phone: phone, source: 'website-hero-demo' }),
        });
        if (res.status === 429) {
          var d429 = await res.json().catch(function () { return {}; });
          throw new Error(d429.detail || "You've already requested a demo recently. Try again in a little while.");
        }
        if (!res.ok) {
          var derr = await res.json().catch(function () { return {}; });
          throw new Error(derr.detail || 'Something went wrong placing the call. Please try again.');
        }
        form.classList.add('hidden');
        var numEl = document.getElementById('demoSuccessNum');
        if (numEl) numEl.textContent = 'Calling ' + phone + ' — keep your phone handy.';
        var successEl = document.getElementById('demoSuccess');
        if (successEl) successEl.classList.remove('hidden');
      } catch (err) {
        btn.disabled = false;
        label.textContent = 'Call me now';
        showErr(err.message || 'Network error — please try again.');
      }
    });
  })();
</script>
```

---

## CHANGE 10 — Modal popup + fix Final CTA link (index.html)

### 10A — Update "Start demo call" button in `#demo` section

**How to find it:** The `#demo` section ("TRY IT LIVE"). The right column card has a large blue button.

**BEFORE:**
```html
<button class="mt-5 w-full inline-flex items-center justify-center gap-2 rounded-full px-6 py-3.5 bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white text-sm shadow-[0_10px_24px_rgba(59,130,246,0.26),inset_0_1px_0_rgba(255,255,255,0.35)] active:shadow-[inset_0_2px_4px_rgba(0,0,0,0.18)] transition-all"><iconify-icon icon="solar:microphone-3-bold" class="text-lg"></iconify-icon> Start demo call</button>
```

**AFTER:**
```html
<button id="openDemoModal" type="button" class="mt-5 w-full inline-flex items-center justify-center gap-2 rounded-full px-6 py-3.5 bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white text-sm shadow-[0_10px_24px_rgba(59,130,246,0.26),inset_0_1px_0_rgba(255,255,255,0.35)] hover:from-blue-400 hover:to-blue-500 hover:-translate-y-0.5 active:shadow-[inset_0_2px_4px_rgba(0,0,0,0.18)] transition-all"><iconify-icon icon="solar:phone-calling-rounded-bold" class="text-lg"></iconify-icon> Get a demo call</button>
```

### 10B — Fix Final CTA "Book a call" link

**How to find it:** The `#book` section (dark panel near the bottom). There is a "Book a call" `<a>` tag with a broken `cal.com` href.

**BEFORE:**
```html
<a href="https://cal.com" target="_blank" rel="noopener" class="inline-flex items-center justify-center gap-2 rounded-full px-6 py-3.5 bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white text-sm shadow-[0_10px_24px_rgba(59,130,246,0.3),inset_0_1px_0_rgba(255,255,255,0.35)] hover:-translate-y-0.5 transition-all">Book a call <iconify-icon icon="solar:arrow-right-linear" style="stroke-width:1.5;" class="text-lg"></iconify-icon></a>
```

**AFTER (only the `href` changes):**
```html
<a href="https://calendly.com/harvindersran101/intro-call" target="_blank" rel="noopener" class="inline-flex items-center justify-center gap-2 rounded-full px-6 py-3.5 bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white text-sm shadow-[0_10px_24px_rgba(59,130,246,0.3),inset_0_1px_0_rgba(255,255,255,0.35)] hover:-translate-y-0.5 transition-all">Book a call <iconify-icon icon="solar:arrow-right-linear" style="stroke-width:1.5;" class="text-lg"></iconify-icon></a>
```

### 10C — Add modal HTML

**How to find it:** The `</main>` closing tag. Paste this block immediately before `</main>`.

**ADD (new HTML block — does not replace anything):**
```html
<!-- ===================== DEMO CALL MODAL ===================== -->
<div id="demoModal" style="display:none" class="fixed inset-0 z-[200] flex items-center justify-center p-4">
  <div id="demoModalBackdrop" class="vx-modal-bd absolute inset-0 bg-slate-900/50 backdrop-blur-md"></div>
  <div class="vx-modal-card relative z-10 w-full max-w-sm bg-white rounded-[2rem] border border-slate-200/80 shadow-[0_40px_100px_-20px_rgba(15,23,42,0.55),inset_0_2px_0_rgba(255,255,255,1)] overflow-hidden">
    <div class="px-5 py-4 flex items-center justify-between border-b border-slate-100">
      <div class="flex items-center gap-3">
        <span class="w-9 h-9 rounded-xl bg-blue-50 border border-blue-100 flex items-center justify-center text-blue-500 shadow-[inset_0_1px_0_white]">
          <iconify-icon icon="solar:phone-calling-rounded-bold" class="text-lg"></iconify-icon>
        </span>
        <div>
          <p class="text-sm font-medium text-slate-900">Get a demo call</p>
          <p class="text-[11px] text-slate-400 font-light mt-0.5">We'll call your phone in ~10 seconds</p>
        </div>
      </div>
      <button id="closeDemoModal" type="button" aria-label="Close"
        class="w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 flex items-center justify-center text-slate-500 hover:text-slate-700 transition-colors shrink-0">
        <iconify-icon icon="solar:close-linear" class="text-base"></iconify-icon>
      </button>
    </div>
    <div class="p-5">
      <form id="modalDemoForm" novalidate class="space-y-3">
        <input id="m-name" name="name" required placeholder="Your name" autocomplete="name"
          class="w-full rounded-xl bg-slate-50 border border-slate-200 px-3.5 py-2.5 text-sm text-slate-800 placeholder:text-slate-400 shadow-[inset_0_1px_2px_rgba(15,23,42,0.04)] focus:outline-none focus:ring-2 focus:ring-blue-400/40 focus:border-blue-300 focus:bg-white transition" />
        <input id="m-email" name="email" type="email" required placeholder="Email address" autocomplete="email"
          class="w-full rounded-xl bg-slate-50 border border-slate-200 px-3.5 py-2.5 text-sm text-slate-800 placeholder:text-slate-400 shadow-[inset_0_1px_2px_rgba(15,23,42,0.04)] focus:outline-none focus:ring-2 focus:ring-blue-400/40 focus:border-blue-300 focus:bg-white transition" />
        <div class="flex items-center gap-2">
          <span class="inline-flex items-center gap-1 rounded-xl bg-slate-100 border border-slate-200 px-3 py-2.5 text-sm text-slate-500 shrink-0 select-none shadow-[inset_0_1px_2px_rgba(15,23,42,0.04)]">🇮🇳 +91</span>
          <input id="m-phone" name="phone" inputmode="numeric" required placeholder="10-digit number" autocomplete="tel"
            class="flex-1 min-w-0 rounded-xl bg-slate-50 border border-slate-200 px-3.5 py-2.5 text-sm text-slate-800 placeholder:text-slate-400 shadow-[inset_0_1px_2px_rgba(15,23,42,0.04)] focus:outline-none focus:ring-2 focus:ring-blue-400/40 focus:border-blue-300 focus:bg-white transition" />
        </div>
        <p id="m-error" class="hidden text-red-500 text-xs px-1 leading-4"></p>
        <button id="m-submit" type="submit"
          class="w-full inline-flex items-center justify-center gap-2 rounded-full px-6 py-3 bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white text-sm font-medium shadow-[0_10px_24px_rgba(59,130,246,0.26),inset_0_1px_0_rgba(255,255,255,0.35)] hover:from-blue-400 hover:to-blue-500 hover:-translate-y-0.5 active:shadow-[inset_0_2px_4px_rgba(0,0,0,0.18)] transition-all disabled:opacity-60 disabled:cursor-not-allowed disabled:translate-y-0">
          <iconify-icon icon="solar:phone-calling-rounded-bold" class="text-lg"></iconify-icon>
          <span id="m-label">Call me now</span>
        </button>
        <p class="text-[11px] text-slate-400 font-light text-center leading-4">We'll call within ~10 seconds · 1 demo per number</p>
      </form>
      <div id="modalSuccess" class="hidden text-center py-6 space-y-3">
        <div class="w-14 h-14 mx-auto rounded-full bg-emerald-50 border border-emerald-100 flex items-center justify-center">
          <iconify-icon icon="solar:phone-calling-rounded-bold" class="text-2xl text-emerald-500"></iconify-icon>
        </div>
        <p class="text-base font-medium text-slate-900">Calling you now</p>
        <p id="modalSuccessNum" class="text-sm text-slate-500 font-light">Keep your phone handy.</p>
        <a href="https://calendly.com/harvindersran101/intro-call" target="_blank" rel="noopener"
          class="inline-flex items-center gap-1.5 text-xs text-blue-500 hover:text-blue-600 transition-colors">
          Book a full demo <iconify-icon icon="solar:arrow-right-linear" class="text-sm"></iconify-icon>
        </a>
      </div>
    </div>
  </div>
</div>
```

### 10D — Add modal JavaScript

**How to find it:** Before the closing `</body>` tag. Add this block **before** the hero form script added in Change 9C.

**ADD (new script block — does not replace anything):**
```html
<script>
  // ---- Demo call modal ----
  (function () {
    var modal    = document.getElementById('demoModal');
    var backdrop = document.getElementById('demoModalBackdrop');
    var openBtn  = document.getElementById('openDemoModal');
    var closeBtn = document.getElementById('closeDemoModal');
    var ENDPOINT = 'https://api.voxioai.com/api/demo-call';

    function openModal() {
      modal.style.display = 'flex';
      document.body.style.overflow = 'hidden';
      document.getElementById('m-name').focus();
    }

    function closeModal() {
      modal.style.display = 'none';
      document.body.style.overflow = '';
      var form    = document.getElementById('modalDemoForm');
      var success = document.getElementById('modalSuccess');
      var errEl   = document.getElementById('m-error');
      var btn     = document.getElementById('m-submit');
      var lbl     = document.getElementById('m-label');
      if (form)    { form.reset(); form.classList.remove('hidden'); }
      if (success) { success.classList.add('hidden'); }
      if (errEl)   { errEl.textContent = ''; errEl.classList.add('hidden'); }
      if (btn)     { btn.disabled = false; }
      if (lbl)     { lbl.textContent = 'Call me now'; }
    }

    if (openBtn)  openBtn.addEventListener('click', openModal);
    if (closeBtn) closeBtn.addEventListener('click', closeModal);
    if (backdrop) backdrop.addEventListener('click', closeModal);
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && modal.style.display === 'flex') closeModal();
    });

    var form  = document.getElementById('modalDemoForm');
    var errEl = document.getElementById('m-error');
    var btn   = document.getElementById('m-submit');
    var lbl   = document.getElementById('m-label');
    if (!form) return;

    function showErr(m) { errEl.textContent = m; errEl.classList.remove('hidden'); }

    form.addEventListener('submit', async function (e) {
      e.preventDefault();
      errEl.classList.add('hidden');
      var name   = document.getElementById('m-name').value.trim();
      var email  = document.getElementById('m-email').value.trim();
      var digits = document.getElementById('m-phone').value.replace(/\D/g, '');
      if (name.length < 2)               return showErr('Please enter your name.');
      if (!/^\S+@\S+\.\S+$/.test(email)) return showErr('Please enter a valid email.');
      if (digits.length !== 10)          return showErr('Enter a 10-digit Indian mobile number.');
      var phone = '+91' + digits;
      btn.disabled = true;
      lbl.textContent = 'Connecting…';
      try {
        var res = await fetch(ENDPOINT, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name: name, email: email, phone: phone, source: 'website-demo-modal' }),
        });
        if (res.status === 429) {
          var d = await res.json().catch(function () { return {}; });
          throw new Error(d.detail || "You've already requested a demo recently. Try again in a little while.");
        }
        if (!res.ok) {
          var d = await res.json().catch(function () { return {}; });
          throw new Error(d.detail || 'Something went wrong. Please try again.');
        }
        form.classList.add('hidden');
        var numEl = document.getElementById('modalSuccessNum');
        if (numEl) numEl.textContent = 'Calling ' + phone + ' — keep your phone handy.';
        document.getElementById('modalSuccess').classList.remove('hidden');
      } catch (err) {
        btn.disabled = false;
        lbl.textContent = 'Call me now';
        showErr(err.message || 'Network error — please try again.');
      }
    });
  })();
</script>
```

---

## Script order near `</body>` (final state)

The bottom of `index.html` before `</body>` must have scripts in this order:

```
1. The main site scripts block (waveform bars, play/pause, currency toggle, mobile nav, scroll reveal)
2. [NEW] Modal JS script  ← Change 10D
3. [NEW] Hero form JS script  ← Change 9C
```

---

## Verification checklist

After applying all changes, run `python -m http.server 3000` and open `http://localhost:3000`:

- [ ] Blue animation cloud is in the lower-right quadrant of the page
- [ ] Nav logo shows only "VoxioAI" — no "Voice AI Agency" tagline
- [ ] Hero section has NO "VOICE AI AGENCY" pill chip above the headline
- [ ] Hero right panel shows a form (name / email / phone) — NOT a chat transcript
- [ ] "TRY IT LIVE" section button says "Get a demo call" — clicking it opens a modal
- [ ] Modal has a blurred backdrop, solid white card, X button, and name/email/phone form
- [ ] Pressing Escape or clicking the backdrop closes and resets the modal
- [ ] Final CTA "Book a call" button links to `https://calendly.com/harvindersran101/intro-call`
- [ ] Recording cards have NO coloured badges; each shows title + subtitle + duration in header
