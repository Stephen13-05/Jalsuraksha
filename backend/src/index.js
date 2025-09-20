import express from 'express';
import cron from 'node-cron';
import { TZ } from './config/index.js';
import { runHourly, computeDailyCases } from './jobs/hourlyJob.js';
import { runDaily } from './jobs/dailyJob.js';

const app = express();
app.use(express.json());

// Simple landing page so visiting http://localhost:8080 shows useful info
app.get('/', (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.end(`
    <!doctype html>
    <html>
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>JalArogya Backend</title>
      <style>
        body { font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif; padding: 24px; color: #0f172a; }
        h1 { margin-top: 0; }
        code { background:#f1f5f9; padding:2px 6px; border-radius:4px; }
        .card { border:1px solid #e2e8f0; border-radius:12px; padding:16px; margin:12px 0; background:#ffffff; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
        .btn { display:inline-block; padding:8px 12px; border-radius:8px; background:#16a34a; color:#fff; text-decoration:none; }
        .btn.warn { background:#f59e0b; }
        .btn.danger { background:#ef4444; }
        .muted { color:#64748b; }
      </style>
    </head>
    <body>
      <h1>JalArogya Backend</h1>
      <p class="muted">Timezone: ${TZ}</p>

      <div class="card">
        <h3>Health</h3>
        <p><a class="btn" href="/health">GET /health</a></p>
      </div>

      <div class="card">
        <h3>Manual Triggers</h3>
        <p>POST <code>/run/hourly</code></p>
        <p>POST <code>/run/daily</code> with JSON body <code>{"date":"YYYY-MM-DD"}</code> (optional)</p>
      </div>

      <div class="card">
        <h3>Demo Seeding</h3>
        <p>POST <code>/demo/seed</code> with JSON body:</p>
<pre>{
  "biases": {
    "assam_kamrup_sonapur": "red",
    "assam_nagaon_hojai": "yellow",
    "manipur_imphal_w_langjing": "green"
  }
}</pre>
        <p class="muted">This biases the current hour's generated pH/turbidity/E. coli. Rainfall and daily cases stay real. Smoothing prevents always-RED.</p>
      </div>

      <div class="card">
        <h3>Where to see data in Firestore</h3>
        <ul>
          <li><code>appdata/main/villages/{villageId}/hourly/{ISO_HOUR}</code></li>
          <li><code>appdata/main/villages/{villageId}/status/current_risk</code></li>
          <li><code>appdata/main/villages/{villageId}/daily/{YYYY-MM-DD}</code> (after daily job)</li>
        </ul>
      </div>
    </body>
    </html>
  `);
});

app.get('/health', (req, res) => res.json({ ok: true, timezone: TZ }));

app.post('/run/hourly', async (req, res) => {
  try {
    await runHourly();
    res.json({ ok: true });
  } catch (e) {
    console.error(e);
    res.status(500).json({ ok: false, error: e.message });
  }
});

// --- Debug utilities to verify cases and samples pipeline ---
app.get('/debug/inspect', async (req, res) => {
  try {
    const vid = (req.query?.vid || '').toString();
    if (!vid) return res.status(400).json({ ok: false, error: 'vid required' });
    const { DateTime } = await import('luxon');
    const { TZ, firestore } = await import('./config/index.js');
    const now = DateTime.now().setZone(TZ);
    // minimal village stub
    const vdoc = await firestore.collection('appdata').doc('main').collection('villages').doc(vid).get();
    if (!vdoc.exists) return res.status(404).json({ ok: false, error: 'village not found' });
    const v = { id: vid, ...(vdoc.data() || {}) };
    const out = await computeDailyCases(v, now);
    res.json({ ok: true, today: now.toISODate(), village: vid, result: out });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

app.get('/debug/cases', async (req, res) => {
  try {
    const vid = (req.query?.vid || '').toString();
    const count = Number(req.query?.count || '0');
    if (!vid) return res.status(400).json({ ok: false, error: 'vid required' });
    const { DateTime } = await import('luxon');
    const { TZ, firestore } = await import('./config/index.js');
    const today = DateTime.now().setZone(TZ).toISODate();
    await firestore.collection('appdata').doc('main')
      .collection('ashaworkers_daily_cases').doc(today)
      .collection('villages').doc(vid)
      .set({ count }, { merge: true });
    res.json({ ok: true, vid, today, count });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

app.get('/debug/sample', async (req, res) => {
  try {
    const vid = (req.query?.vid || '').toString();
    if (!vid) return res.status(400).json({ ok: false, error: 'vid required' });
    const ph = Number(req.query?.ph ?? '0');
    const turbidity = Number(req.query?.turbidity ?? '0');
    const ecoli = String(req.query?.ecoli ?? 'false').toLowerCase() === 'true';
    const { DateTime } = await import('luxon');
    const { TZ, firestore } = await import('./config/index.js');
    const today = DateTime.now().setZone(TZ).toISODate();
    await firestore.collection('appdata').doc('main')
      .collection('ashaworkers_samples').doc(today)
      .collection('villages').doc(vid)
      .set({ ph, turbidity, ecoli, updatedAt: new Date().toISOString() }, { merge: true });
    res.json({ ok: true, vid, today, ph, turbidity, ecoli });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// Convenience: allow triggering from browser via GET
app.get('/run/hourly', async (req, res) => {
  try {
    await runHourly();
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ ok: true }));
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

app.post('/run/daily', async (req, res) => {
  try {
    await runDaily(req.body?.date);
    res.json({ ok: true });
  } catch (e) {
    console.error(e);
    res.status(500).json({ ok: false, error: e.message });
  }
});

app.get('/run/daily', async (req, res) => {
  try {
    await runDaily(req.query?.date);
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ ok: true }));
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// Demo seeding: bias risk colors per village for the current hour
// Body example: { "biases": { "assam_kamrup_sonapur": "red", "assam_nagaon_hojai": "yellow" } }
app.post('/demo/seed', async (req, res) => {
  try {
    const biases = (req.body && typeof req.body === 'object') ? (req.body.biases || {}) : {};
    await runHourly(biases);
    res.json({ ok: true, applied: biases });
  } catch (e) {
    console.error(e);
    res.status(500).json({ ok: false, error: e.message });
  }
});

// Convenience: GET /demo/seed?bias=vid1:red,vid2:yellow
app.get('/demo/seed', async (req, res) => {
  try {
    const raw = (req.query?.bias || '').toString();
    const biases = {};
    if (raw) {
      raw.split(',').forEach(pair => {
        const [k, v] = pair.split(':');
        if (k && v) biases[k.trim()] = v.trim();
      });
    }
    await runHourly(biases);
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ ok: true, applied: biases }));
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// Cron schedules (Asia/Kolkata)
cron.schedule('0 * * * *', async () => { // minute 0 of every hour
  try { await runHourly(); } catch (e) { console.error('[cron hourly]', e); }
}, { timezone: TZ });

cron.schedule('55 23 * * *', async () => { // 23:55 daily
  try { await runDaily(); } catch (e) { console.error('[cron daily]', e); }
}, { timezone: TZ });

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Backend listening on port ${PORT} (TZ: ${TZ})`);
  // Bootstrap: create initial data on startup so no manual trigger is needed
  (async () => {
    try {
      await runHourly();
      console.log('[bootstrap] Initial hourly run completed');
    } catch (e) {
      console.error('[bootstrap] Initial hourly run failed:', e.message);
    }
  })();
});
