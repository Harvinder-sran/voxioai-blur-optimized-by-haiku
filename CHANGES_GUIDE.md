# VoxioAI Website — Changes Guide for Porting Agent

> This guide lists every change made to the codebase since the initial build, in chronological order.
> The target codebase is an identical copy of this site at its starting state.
> Apply all 10 changes in order. Files involved: `index.html`, `scene-no-ripple.json`, `vercel.json`.
> **Do NOT open index.html via file:// — always use a local HTTP server (python -m http.server 3000).**

---

## CHANGE 1 — Optimize progressive blur in scene JSON (−30%)

**File:** `scene-no-ripple.json`
**Why:** The progressiveBlur layer was too heavy. Reducing intensity improves render performance.

In `scene-no-ripple.json`, find the layer object where `"type": "progressiveBlur"`.
Inside its `props` object, find the two blur intensity values and reduce them:

```
"blurAmount": 6   →  change to  "blurAmount": 4
"blurAmount": 11  →  change to  "blurAmount": 8
```

(These may appear as separate keys or in an array depending on how the layer stores them — search for `progressiveBlur` and then look for numeric blur values in the same object. Change 6→4 and 11→8.)

---

## CHANGE 2 — Move CSS flow-field animation to bottom-right + shift glow default

**File:** `index.html`
**Where:** Inside the `<script>` block near the bottom — look for the comment
`// Each layer: center (cx,cy in %), size (vw), blur (px), color, stretch (ex,ey),`

**Replace** the entire `var defs = [...]` array (5 objects) with this:

```js
var defs = [
  { cx:78, cy:72, size:46, blur:60, color:'rgba(37,99,235,0.50)',  ex:1.55, ey:0.80, ax:9,  ay:7,  f:[0.17,0.26,0.21,0.13], ph:[0.0,1.3,2.1,0.7], rot:14, depth:9 },
  { cx:92, cy:75,  size:42, blur:62, color:'rgba(56,189,248,0.46)', ex:1.30, ey:0.95, ax:7,  ay:6,  f:[0.13,0.23,0.16,0.29], ph:[1.1,0.2,2.7,1.6], rot:10, depth:15 },
  { cx:85, cy:78, size:36, blur:58, color:'rgba(59,130,246,0.42)', ex:1.40, ey:0.85, ax:11, ay:8,  f:[0.21,0.15,0.27,0.18], ph:[2.4,1.7,0.5,2.0], rot:18, depth:7  },
  { cx:88, cy:70, size:24, blur:38, color:'rgba(96,165,250,0.55)', ex:1.60, ey:0.70, ax:12, ay:9,  f:[0.29,0.19,0.33,0.24], ph:[0.6,2.2,1.1,0.3], rot:24, depth:20 },
  { cx:90, cy:82, size:16, blur:26, color:'rgba(29,78,216,0.45)',  ex:1.20, ey:0.90, ax:10, ay:10, f:[0.34,0.28,0.22,0.37], ph:[1.9,0.9,2.5,1.2], rot:30, depth:26 }
];
```

Then find this line (the pointer state default position):
```js
var p = { nx:0, ny:0, tnx:0, tny:0, cx:0.7, cy:0.25, tcx:0.7, tcy:0.25, active:0, tactive:0 };
```
**Replace with:**
```js
var p = { nx:0, ny:0, tnx:0, tny:0, cx:0.85, cy:0.80, tcx:0.85, tcy:0.80, active:0, tactive:0 };
```

**Effect:** Blue animation cloud moves from upper-center to lower-right. Glow default position follows.

---

## CHANGE 3 — Remove deprecated `name` property from vercel.json

**File:** `vercel.json`

Open `vercel.json`. Remove the `"name"` key/value line entirely.

**Before:**
```json
{
  "name": "voxioai-website",
  "rewrites": [...]
}
```
**After:**
```json
{
  "rewrites": [...]
}
```

---

## CHANGE 4 — Refactor NAV for mobile + refactor recording cards

**File:** `index.html`
**Two sub-changes in one commit.**

### 4A — Nav mobile responsiveness

Find the `<nav>` element (inside `<header>`). Replace the nav wrapper and its inner layout with responsive sizing:

**Old nav wrapper:**
```html
<nav class="max-w-6xl mx-auto px-4 sm:px-6 pt-4">
  <div class="relative overflow-hidden rounded-full bg-white/84 backdrop-blur-2xl border border-white/90 shadow-[0_14px_38px_-22px_rgba(15,23,42,0.42),inset_0_1px_0_rgba(255,255,255,1)] px-3 sm:px-4 py-2.5 sm:py-3">
    <div class="relative z-10 flex items-center justify-between gap-3">
      <a href="#top" class="flex items-center gap-2.5 group">
        <span class="w-9 h-9 rounded-full bg-gradient-to-b from-white to-slate-100 border border-slate-200 shadow-[0_2px_8px_rgba(15,23,42,0.06),inset_0_1px_0_white] flex items-center justify-center text-blue-600">
          <iconify-icon icon="solar:microphone-3-bold" class="text-lg"></iconify-icon>
        </span>
```
**New nav wrapper:**
```html
<nav class="max-w-6xl mx-auto px-2 sm:px-6 pt-2 sm:pt-4">
  <div class="relative overflow-hidden rounded-full bg-white/84 backdrop-blur-2xl border border-white/90 shadow-[0_14px_38px_-22px_rgba(15,23,42,0.42),inset_0_1px_0_rgba(255,255,255,1)] px-2 sm:px-4 py-1.5 sm:py-3">
    <div class="relative z-10 flex items-center justify-between gap-2 sm:gap-3">
      <a href="#top" class="flex items-center gap-1.5 sm:gap-2.5 group">
        <span class="w-7 sm:w-9 h-7 sm:h-9 rounded-full bg-gradient-to-b from-white to-slate-100 border border-slate-200 shadow-[0_2px_8px_rgba(15,23,42,0.06),inset_0_1px_0_white] flex items-center justify-center text-blue-600 shrink-0">
          <iconify-icon icon="solar:microphone-3-bold" class="text-base sm:text-lg"></iconify-icon>
        </span>
```

Find the nav "Book a call" button and hamburger — replace with smaller mobile sizes:

**Old:**
```html
<div class="flex items-center gap-2">
  <a href="#book" class="inline-flex items-center justify-center rounded-full px-4 py-2 text-xs text-white bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 shadow-[0_5px_14px_rgba(59,130,246,0.28),inset_0_1px_0_rgba(255,255,255,0.35)] hover:-translate-y-0.5 transition-all">Book a call</a>
  <button id="navToggle" aria-label="Menu" class="md:hidden w-9 h-9 rounded-full bg-white/78 border border-slate-200 shadow-[inset_0_1px_0_white] flex items-center justify-center text-slate-600"><iconify-icon icon="solar:hamburger-menu-linear" class="text-lg"></iconify-icon></button>
</div>
```
**New:**
```html
<div class="flex items-center gap-1.5 sm:gap-2">
  <a href="#book" class="inline-flex items-center justify-center rounded-full px-2.5 sm:px-4 py-1.5 sm:py-2 text-[11px] sm:text-xs text-white bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 shadow-[0_5px_14px_rgba(59,130,246,0.28),inset_0_1px_0_rgba(255,255,255,0.35)] hover:-translate-y-0.5 transition-all whitespace-nowrap">Book a call</a>
  <button id="navToggle" aria-label="Menu" class="md:hidden w-7 sm:w-9 h-7 sm:h-9 rounded-full bg-white/78 border border-slate-200 shadow-[inset_0_1px_0_white] flex items-center justify-center text-slate-600 shrink-0"><iconify-icon icon="solar:hamburger-menu-linear" class="text-base sm:text-lg"></iconify-icon></button>
</div>
```

### 4B — Recording cards: remove colored badges, move duration to header

Each of the 4 recording `<article>` cards originally had:
- A colored badge pill (Sales / Collections / Outbound / Support) in the header
- Duration shown next to the waveform at the bottom

**Replace each card header + waveform row.** All 4 cards follow the same pattern.

**Old card structure (example — Recording 1):**
```html
<article class="rounded-[1.75rem] bg-white/72 border border-white p-4 sm:p-5 shadow-[0_14px_34px_-26px_rgba(15,23,42,0.32),inset_0_1px_0_white]">
  <div class="flex items-start justify-between gap-3">
    <div class="min-w-0"><h3 class="text-sm font-medium text-slate-900 truncate">Inbound booking — dental clinic</h3><p class="text-xs text-slate-400 font-light mt-0.5">Reception agent · English</p></div>
    <span class="shrink-0 inline-flex items-center gap-1.5 rounded-full bg-blue-50 border border-blue-100 px-2.5 py-1 text-[11px] font-medium text-blue-600"><span class="w-1.5 h-1.5 rounded-full bg-blue-500"></span>Sales</span>
  </div>
  <div class="mt-4 flex items-center gap-3">
    <button data-play ...>...</button>
    <div class="vx-wave flex-1" data-wave data-bars="40"></div>
    <span class="mono text-[11px] text-slate-400 shrink-0 w-10 text-right">0:48</span>
  </div>
</article>
```

**New card structure (example — Recording 1):**
```html
<article class="rounded-[1.75rem] bg-white/72 border border-white p-4 sm:p-5 shadow-[0_14px_34px_-26px_rgba(15,23,42,0.32),inset_0_1px_0_white]">
  <div class="flex items-start justify-between gap-2">
    <h3 class="text-sm font-medium text-slate-900">Inbound booking — dental clinic</h3>
    <span class="mono text-[11px] text-slate-400 shrink-0">0:48</span>
  </div>
  <div class="mt-4 flex items-center gap-3">
    <button data-play ...>...</button>
    <div class="vx-wave flex-1" data-wave data-bars="40"></div>
  </div>
</article>
```

Apply the same pattern to all 4 cards with their respective titles and durations:
- Card 1: "Inbound booking — dental clinic" · `0:48`
- Card 2: "Collections reminder — fintech" · `1:12`
- Card 3: "Outbound follow-up — solar leads" · `0:54`
- Card 4: "Support triage — SaaS helpdesk" · `1:31`

---

## CHANGE 5 — Add agent descriptions back to recording cards

**File:** `index.html`
**Why:** After Change 4 removed the badge, the subtitle description was lost too. Add it back under each card title.

For each of the 4 recording cards, wrap the `<h3>` in a `<div class="min-w-0">` and add a `<p>` subtitle below it.

**Pattern (wrap the lone h3 like this):**
```html
<div class="flex items-start justify-between gap-2">
  <div class="min-w-0">
    <h3 class="text-sm font-medium text-slate-900">TITLE HERE</h3>
    <p class="text-xs text-slate-400 font-light mt-0.5">SUBTITLE HERE</p>
  </div>
  <span class="mono text-[11px] text-slate-400 shrink-0">DURATION</span>
</div>
```

Subtitles for each card:
- Card 1: `Reception agent · English`
- Card 2: `Outbound agent · Hindi + English`
- Card 3: `Sales agent · English`
- Card 4: `Support agent · English`

---

## CHANGE 6 — Move animation Y position in scene JSON (0.5 → 0.8)

**File:** `scene-no-ripple.json`

Find the `flowField` layer (the one where `"type": "flowField"`).
Inside its transform or position properties, find `"y": 0.5` and change it to `"y": 0.8`.

---

## CHANGE 7 — Remove "Voice AI Agency" from nav and hero section

**File:** `index.html`
**Two places.**

### 7A — Nav logo: remove the tagline span

Find the nav logo `<a href="#top">` block. The logo currently has a `<span class="flex flex-col">` wrapper with two child spans (VoxioAI + Voice AI Agency tagline). Simplify it to just the name span:

**Old:**
```html
<span class="flex flex-col leading-none">
  <span class="mono text-xs sm:text-sm font-semibold tracking-[-0.08em] text-slate-950 group-hover:text-blue-600 transition-colors">VoxioAI</span>
  <span class="hidden md:block mt-0.5 text-[10px] font-light tracking-[-0.03em] text-slate-400">Voice AI Agency</span>
</span>
```
**New:**
```html
<span class="mono text-xs sm:text-sm font-semibold tracking-[-0.08em] text-slate-950 group-hover:text-blue-600 transition-colors">VoxioAI</span>
```

### 7B — Hero: remove the "VOICE AI AGENCY" chip above the h1

In the hero `<!-- Copy -->` div, before the `<h1>`, there is a pill chip:
```html
<div class="inline-flex items-center gap-2 rounded-full bg-white/75 border border-white px-3.5 py-2 shadow-[0_6px_18px_-12px_rgba(15,23,42,0.3),inset_0_1px_0_white] mb-7">
  <span class="w-7 h-7 rounded-full bg-gradient-to-b from-blue-50 to-white border border-blue-100 shadow-[inset_0_1px_0_white] flex items-center justify-center">
    <iconify-icon icon="solar:microphone-3-linear" style="stroke-width:1.5;" class="text-base text-blue-500"></iconify-icon>
  </span>
  <span class="mono text-xs font-medium tracking-[-0.04em] text-slate-500">VOICE AI AGENCY</span>
</div>
```
**Delete the entire div above.** The `<h1>` becomes the first element in the copy block.

---

## CHANGE 8 — Move animation Y position UP (0.8 → 0.1)

**File:** `scene-no-ripple.json`

Same field as Change 6. Find the `flowField` layer, find `"y": 0.8`, change to `"y": 0.1`.

> NOTE: Changes 6 and 8 both edit the same value — apply them in order and the final value is `0.1`.

---

## CHANGE 9 — Replace hero panel fake chat with live "Call me now" form

**File:** `index.html`

### 9A — Add modal animation CSS

Inside the `<style>` block, at the very end (just before the closing `</style>`), add:

```css
/* Demo call modal */
@keyframes vxModalIn{from{opacity:0;transform:scale(0.96) translateY(10px)}to{opacity:1;transform:scale(1) translateY(0)}}
.vx-modal-card{animation:vxModalIn .22s cubic-bezier(.22,1,.36,1)}
@keyframes vxBdIn{from{opacity:0}to{opacity:1}}
.vx-modal-bd{animation:vxBdIn .18s ease}
```

### 9B — Replace the hero right panel content

Find the hero section right panel. It contains a fake "Live call" chat transcript with three message bubbles. The outer wrapper is a div with class `relative rounded-[2rem] bg-[#f8fafc] border border-white ...`.

**Find this block** (the inner card header + chat messages + waveform):

```html
<div class="px-4 sm:px-5 py-3.5 flex items-center justify-between border-b border-slate-200/80">
  <div class="flex items-center gap-2">
    <span class="w-2 h-2 rounded-full bg-emerald-500 vx-pulse"></span>
    <span class="text-xs text-slate-600">Live call · 00:48</span>
  </div>
  <span class="mono text-[11px] text-slate-400 tracking-[-0.05em]">VOXIO AGENT</span>
</div>
<div class="p-4 sm:p-5 space-y-3">
  ... (3 chat bubbles + waveform row) ...
</div>
```

**Replace the entire inner rounded card content** (keep the outer `relative rounded-[2rem]` wrapper and the `rounded-[1.5rem]` inner card — replace only what's inside the inner card):

```html
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
```

### 9C — Add hero form JavaScript

Before the closing `</body>` tag, add this `<script>` block:

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

## CHANGE 10 — Demo call modal + fix final CTA link

**File:** `index.html`
**Three sub-changes.**

### 10A — Update "Start demo call" button in TRY IT LIVE section

Find this button in the `#demo` section:
```html
<button class="mt-5 w-full inline-flex items-center justify-center gap-2 rounded-full px-6 py-3.5 bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white text-sm shadow-[0_10px_24px_rgba(59,130,246,0.26),inset_0_1px_0_rgba(255,255,255,0.35)] active:shadow-[inset_0_2px_4px_rgba(0,0,0,0.18)] transition-all"><iconify-icon icon="solar:microphone-3-bold" class="text-lg"></iconify-icon> Start demo call</button>
```
**Replace with:**
```html
<button id="openDemoModal" type="button" class="mt-5 w-full inline-flex items-center justify-center gap-2 rounded-full px-6 py-3.5 bg-gradient-to-b from-blue-500 to-blue-600 border border-blue-700 text-white text-sm shadow-[0_10px_24px_rgba(59,130,246,0.26),inset_0_1px_0_rgba(255,255,255,0.35)] hover:from-blue-400 hover:to-blue-500 hover:-translate-y-0.5 active:shadow-[inset_0_2px_4px_rgba(0,0,0,0.18)] transition-all"><iconify-icon icon="solar:phone-calling-rounded-bold" class="text-lg"></iconify-icon> Get a demo call</button>
```

### 10B — Fix final CTA "Book a call" link

In the `#book` section (Final CTA), find:
```html
<a href="https://cal.com" target="_blank" rel="noopener" class="...">Book a call ...</a>
```
**Change** `href="https://cal.com"` to `href="https://calendly.com/harvindersran101/intro-call"`.

### 10C — Add modal HTML before `</main>`

Just before `</main>` (and before the SCRIPTS comment), paste this block:

```html
<!-- ===================== DEMO CALL MODAL ===================== -->
<div id="demoModal" style="display:none" class="fixed inset-0 z-[200] flex items-center justify-center p-4">
  <!-- Backdrop: blurs everything behind -->
  <div id="demoModalBackdrop" class="vx-modal-bd absolute inset-0 bg-slate-900/50 backdrop-blur-md"></div>
  <!-- Card -->
  <div class="vx-modal-card relative z-10 w-full max-w-sm bg-white rounded-[2rem] border border-slate-200/80 shadow-[0_40px_100px_-20px_rgba(15,23,42,0.55),inset_0_2px_0_rgba(255,255,255,1)] overflow-hidden">
    <!-- Header -->
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
    <!-- Form body -->
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
      <!-- Success state -->
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

Before the closing `</body>` tag, add this `<script>` block (add it BEFORE the hero form script from Change 9):

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

## API Contract (for verification)

The demo form posts to:
```
POST https://api.voxioai.com/api/demo-call
Content-Type: application/json
{ "name": "...", "email": "...", "phone": "+91XXXXXXXXXX", "source": "website-hero-demo" }
```

| Status | Meaning |
|--------|---------|
| `200` | Call dispatched — show success state |
| `429` | Cooldown / daily cap — show `detail` message |
| `4xx` | Validation error — show `detail` message |
| `5xx` | Server error — show generic retry message |

Phone normalisation: frontend strips non-digits, prepends `+91`. Backend accepts bare 10-digit too.

---

## Checklist for porting agent

- [ ] Change 1 — `scene-no-ripple.json` progressive blur: 6→4, 11→8
- [ ] Change 2 — `index.html` flow-field `defs` array: all 5 cx/cy values + pointer default position
- [ ] Change 3 — `vercel.json` remove `"name"` key
- [ ] Change 4A — `index.html` nav: smaller mobile padding/sizing
- [ ] Change 4B — `index.html` recording cards: remove colored badges, move duration to header
- [ ] Change 5 — `index.html` recording cards: re-add subtitle `<p>` under each h3
- [ ] Change 6 — `scene-no-ripple.json` flowField `y`: 0.5 → 0.8
- [ ] Change 7A — `index.html` nav: remove "Voice AI Agency" tagline span, simplify logo to single span
- [ ] Change 7B — `index.html` hero: remove VOICE AI AGENCY chip div above h1
- [ ] Change 8 — `scene-no-ripple.json` flowField `y`: 0.8 → 0.1 (final value after 6+8 = 0.1)
- [ ] Change 9A — `index.html` `<style>`: add modal CSS keyframes
- [ ] Change 9B — `index.html` hero panel: replace fake chat with demo form HTML
- [ ] Change 9C — `index.html` before `</body>`: add hero form JS script
- [ ] Change 10A — `index.html` #demo section: update "Start demo call" button → `id="openDemoModal"`
- [ ] Change 10B — `index.html` Final CTA: fix `cal.com` → correct Calendly URL
- [ ] Change 10C — `index.html` before `</main>`: add modal HTML
- [ ] Change 10D — `index.html` before `</body>`: add modal JS script (before Change 9C script)

**Verify:** run `python -m http.server 3000` in the project folder, open http://localhost:3000. Never open as file://.
