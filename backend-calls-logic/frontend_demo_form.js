/* ════════════════════════════════════════════════════════════════════════
   VoxioAI — "Call me now" demo form
   Source: index.html from VoxioAI Website Original
   Copy/adapt this into the new website's form component.

   CONTRACT:
     POST https://api.voxioai.com/api/demo-call
     Body:  { name, email, phone, source }
     200:   { status: "calling", room: "vox-..." }  → show success state
     429:   quota hit                               → show quota message
     4xx:   validation error                        → show error message
     5xx:   server error                            → show generic retry message
   ════════════════════════════════════════════════════════════════════════ */

const DEMO_CALL_ENDPOINT = "https://api.voxioai.com/api/demo-call";
const CALENDLY_URL = "https://calendly.com/harvindersran101/intro-call";

/* Wire all [data-calendly] links */
document.querySelectorAll('[data-calendly]').forEach(a => {
  a.href = CALENDLY_URL;
});

/* ── Form logic ─────────────────────────────────────────────────────────── */
const form    = document.getElementById('demoForm');
const errEl   = document.getElementById('d-error');
const btn     = document.getElementById('d-submit');
const label   = document.getElementById('d-label');

const showErr = m => {
  errEl.textContent = m;
  errEl.classList.remove('hidden');
};

form.addEventListener('submit', async (e) => {
  e.preventDefault();
  errEl.classList.add('hidden');

  const name   = document.getElementById('d-name').value.trim();
  const email  = document.getElementById('d-email').value.trim();
  const digits = document.getElementById('d-phone').value.replace(/\D/g, '');

  /* Client-side validation */
  if (name.length < 2)                      return showErr('Please enter your name.');
  if (!/^\S+@\S+\.\S+$/.test(email))        return showErr('Please enter a valid email.');
  if (digits.length !== 10)                 return showErr('Enter a 10-digit Indian mobile number.');

  const phone = '+91' + digits;

  btn.disabled = true;
  label.textContent = 'Connecting…';

  try {
    const res = await fetch(DEMO_CALL_ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, email, phone, source: 'website-hero-demo' }),
    });

    if (res.status === 429) {
      /* Could be cooldown (same number recently called) or daily cap */
      const data = await res.json().catch(() => ({}));
      throw new Error(data.detail || "You've already requested a demo recently. Try again in a little while.");
    }
    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      throw new Error(data.detail || 'Something went wrong placing the call. Please try again.');
    }

    /* SUCCESS — show the "calling" state */
    form.classList.add('hidden');
    const successNum = document.getElementById('demoSuccessNum');
    if (successNum) successNum.textContent = 'Calling ' + phone + ' — keep your phone handy.';
    const successEl = document.getElementById('demoSuccess');
    if (successEl) successEl.classList.remove('hidden');

  } catch (err) {
    btn.disabled = false;
    label.textContent = 'Call me now';
    showErr(err.message || 'Network error — please try again.');
  }
});

/*
  EXPECTED HTML ELEMENTS (adapt IDs/classes to your framework):

  <form id="demoForm" novalidate>
    <input id="d-name"  name="name"  required placeholder="Your name" />
    <input id="d-email" name="email" type="email" required placeholder="Email" />
    <input id="d-phone" name="phone" inputmode="numeric" required placeholder="Phone number" />
    <p id="d-error" class="hidden text-red-500 text-xs"></p>
    <button id="d-submit" type="submit">
      <span id="d-label">Call me now</span>
    </button>
    <p>We'll call within ~60 seconds · 1 demo per number</p>
  </form>

  <div id="demoSuccess" class="hidden">
    <p>Calling you now 📞</p>
    <p id="demoSuccessNum">Keep your phone handy.</p>
  </div>
*/
