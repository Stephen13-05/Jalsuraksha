import { DateTime } from 'luxon';
import { firestore, TZ, Timestamp } from '../config/index.js';
import { readFileSync } from 'fs';
const villages = JSON.parse(readFileSync(new URL('../config/villages.json', import.meta.url), 'utf8'));
import { generateAll, generateBiased } from '../generator.js';
import { evaluateHourly } from '../ruleEngine.js';

// Seasonal rainfall generator for NE India. No external API.
// Jun–Sep (peak monsoon): frequent heavy showers
// Apr–May, Oct–Nov (shoulder): occasional moderate rain
// Dec–Mar (dry): light/rare
function seasonalRainfall(now, lat, lon) {
  const m = now.month; // 1..12
  const h = now.hour;  // 0..23

  // Diurnal boost: more showers 14:00–20:00 local
  const hourBoost = (h >= 14 && h <= 20) ? 1.25 : 1.0;

  // Orographic boost for NE hill belt (very rough band)
  const orography = (lat && lat >= 24 && lat <= 27.5) ? 1.12 : 1.0;

  // Month profiles tuned for NE India, with very heavy Jul–Aug and high Sep
  // Each entry = [baseProbPerHour, minMM, maxMM]
  const profiles = {
    1: [0.10, 0.0, 2.0],
    2: [0.10, 0.0, 2.0],
    3: [0.12, 0.0, 3.0],
    4: [0.28, 0.5, 8.0],
    5: [0.32, 0.8, 10.0],
    6: [0.45, 1.5, 20.0],     // early monsoon
    7: [0.68, 3.0, 35.0],     // peak monsoon
    8: [0.68, 3.0, 35.0],     // peak monsoon
    9: [0.52, 2.0, 22.0],     // retreating but still high
    10: [0.30, 0.5, 10.0],
    11: [0.22, 0.3, 8.0],
    12: [0.12, 0.0, 3.0],
  };

  const [baseProb, minMM, maxMM] = profiles[m] || [0.12, 0.0, 3.0];
  const prob = Math.min(0.97, baseProb * hourBoost * orography);
  if (Math.random() > prob) return { rainfall_mm: 0 };

  // Heavy-burst tail during Jul–Sep
  let mm;
  if (m >= 7 && m <= 9 && Math.random() < 0.30) {
    mm = minMM + Math.random() * (maxMM * 1.5 - minMM);
  } else {
    mm = minMM + Math.random() * (maxMM - minMM);
  }
  return { rainfall_mm: Number(mm.toFixed(2)) };
}

// Deterministic pseudo-random in [0,1) from a key
function prand01(key) {
  let h = 2166136261 >>> 0;
  for (let i = 0; i < key.length; i++) {
    h ^= key.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  // xorshift
  h ^= h << 13; h ^= h >>> 17; h ^= h << 5;
  return ((h >>> 0) % 10000) / 10000;
}

// Pick a bias color for a village & hour to make the map look realistic
function decideBias(villageId, now, rainfall_mm) {
  const m = now.month;
  const hourKey = now.toFormat('yyyyLLddHH');
  const r = prand01(`${villageId}|${hourKey}`);

  // Base monthly distribution (green,yellow,red)
  let probs;
  if (m === 7 || m === 8) {
    probs = [0.45, 0.35, 0.20]; // peak monsoon shows more yellow/red
  } else if (m === 6 || m === 9) {
    probs = [0.55, 0.30, 0.15];
  } else if (m === 10 || m === 11 || m === 5) {
    probs = [0.65, 0.28, 0.07];
  } else {
    probs = [0.78, 0.18, 0.04];
  }

  // If heavy rainfall this hour, nudge towards yellow/red
  if (rainfall_mm >= 10) {
    probs = [Math.max(0, probs[0] - 0.10), probs[1] + 0.06, probs[2] + 0.04];
  } else if (rainfall_mm >= 3) {
    probs = [Math.max(0, probs[0] - 0.05), probs[1] + 0.04, probs[2] + 0.01];
  }
  // Normalize
  const s = probs[0] + probs[1] + probs[2];
  probs = probs.map(p => p / s);

  if (r < probs[0]) return 'green';
  if (r < probs[0] + probs[1]) return 'yellow';
  return 'red';
}

export async function computeDailyCases(v, now) {
  const todayKey = now.toISODate();
  let daily_cases = 0;
  let source = 'none';
  function extractCaseCount(obj) {
    if (!obj || typeof obj !== 'object') return 0;
    if (typeof obj.cases === 'number') return Number(obj.cases) || 0;
    if (typeof obj.caseCount === 'number') return Number(obj.caseCount) || 0;
    if (typeof obj.count === 'number') return Number(obj.count) || 0;
    if (typeof obj.affectedCount === 'number') return Number(obj.affectedCount) || 0;
    if (typeof obj.affected === 'boolean') return obj.affected ? 1 : 0;
    if (typeof obj.affected_count === 'number') return Number(obj.affected_count) || 0;
    if (Array.isArray(obj.affected_list)) return obj.affected_list.length;
    if (Array.isArray(obj.patients)) return obj.patients.length;
    return 0;
  }
  function isSameYMD(dLike, ymd) {
    try {
      if (!dLike) return false;
      // Firestore Timestamp
      if (dLike._seconds || (dLike.seconds && typeof dLike.seconds === 'number')) {
        const ms = (dLike._seconds ?? dLike.seconds) * 1000;
        const d = new Date(ms);
        const s = d.toISOString().slice(0,10);
        return s === ymd;
      }
      const s = typeof dLike === 'string' ? dLike : String(dLike);
      // allow YYYY-MM-DD or full ISO
      const norm = s.length >= 10 ? s.slice(0,10) : s;
      return norm === ymd;
    } catch { return false; }
  }
  function isSameYMDAny(obj, ymd) {
    try {
      if (!obj || typeof obj !== 'object') return false;
      const cand = [obj.date, obj.createdAt, obj.reportedAt, obj.timestamp, obj.time, obj.updatedAt];
      for (const c of cand) {
        if (isSameYMD(c, ymd)) return true;
      }
      return false;
    } catch { return false; }
  }
  try {
    // Preferred: consolidated counter per village
    const casesDoc = await firestore
      .collection('appdata').doc('main')
      .collection('ashaworkers_daily_cases')
      .doc(todayKey).collection('villages').doc(v.id)
      .get();
    if (casesDoc.exists) {
      daily_cases = Number(casesDoc.data()?.count || 0);
      source = 'ashaworkers_daily_cases';
    } else {
      // Fallback A: scan ASHA "reports" style collections for today's affected entries
      // Try common paths in priority order
      const candidateCollections = [
        'ashaworkers_reports', // expected for reports tab
        'asha_reports',        // alternate naming
        'reports',             // generic
      ];
      for (const colName of candidateCollections) {
        try {
          const rawCol = firestore.collection('appdata').doc('main').collection(colName);
          const rawSnap = await rawCol.where('villageId', '==', v.id).get();
          let local = 0;
          rawSnap.forEach(d => {
            const obj = d.data();
            if (isSameYMDAny(obj, todayKey)) local += extractCaseCount(obj);
          });
          if (local === 0) {
            // Try name/district fallback if schema differs
            const rawSnap2 = await rawCol
              .where('village', '==', v.name)
              .where('district', '==', v.district)
              .get();
            rawSnap2.forEach(d => {
              const obj = d.data();
              if (isSameYMDAny(obj, todayKey)) local += extractCaseCount(obj);
            });
          }
          // Also try date-partitioned hierarchical storage patterns
          if (local === 0) {
            try {
              // Pattern 1: appdata/main/{colName}/{YYYY-MM-DD}/villages/{vid}
              const vDoc = await firestore
                .collection('appdata').doc('main')
                .collection(colName).doc(todayKey)
                .collection('villages').doc(v.id)
                .get();
              if (vDoc.exists) {
                const data = vDoc.data() || {};
                // Either a combined count or a summary with affected flag/count
                local += extractCaseCount(data);
              }
            } catch (_) { /* continue */ }

            try {
              // Pattern 1b: sum nested workers under village
              const workersSnap = await firestore
                .collection('appdata').doc('main')
                .collection(colName).doc(todayKey)
                .collection('villages').doc(v.id)
                .collection('workers')
                .get();
              workersSnap.forEach(d => { local += extractCaseCount(d.data()); });
            } catch (_) { /* ignore */ }

            try {
              // Pattern 2: appdata/main/{colName}/{YYYY-MM-DD}/workers where each has villageId/name/district
              const workers2 = await firestore
                .collection('appdata').doc('main')
                .collection(colName).doc(todayKey)
                .collection('workers')
                .where('villageId', '==', v.id)
                .get();
              workers2.forEach(d => { local += extractCaseCount(d.data()); });
              if (local === 0) {
                const wByName = await firestore
                  .collection('appdata').doc('main')
                  .collection(colName).doc(todayKey)
                  .collection('workers')
                  .where('village', '==', v.name)
                  .where('district', '==', v.district)
                  .get();
                wByName.forEach(d => { local += extractCaseCount(d.data()); });
              }
            } catch (_) { /* continue */ }
          }
          if (local > 0) {
            daily_cases = local;
            source = `${colName}`;
            break;
          }
        } catch (_) { /* try next candidate */ }
      }
    }
  } catch (_) { /* keep 0 */ }
  return { daily_cases, source };
}

export async function runHourly(biases = {}) {
  if (!firestore) throw new Error('Firestore not initialized');
  const now = DateTime.now().setZone(TZ);
  const isoHour = now.toUTC().toISO({ suppressMilliseconds: true }).slice(0, 13); // YYYY-MM-DDTHH

  for (const v of villages) {
    const base = firestore.collection('appdata').doc('main').collection('villages').doc(v.id);
    const { daily_cases, source: casesSource } = await computeDailyCases(v, now);
    console.log(`[hourly] ${v.id} cases=${daily_cases} source=${casesSource}`);

    const hourlyRef = base.collection('hourly').doc(isoHour);
    const existing = await hourlyRef.get();
    let payload;

    // rainfall (seasonal dummy)
    const { rainfall_mm } = seasonalRainfall(now, v.lat, v.lon);

    // Prefer ASHA submitted water sample for this hour if present
    let ashaSample = null;
    try {
      const ashaDoc = await firestore
        .collection('appdata').doc('main')
        .collection('ashaworkers_samples')
        .doc(now.toISODate()).collection('villages').doc(v.id)
        .get();
      if (ashaDoc.exists) ashaSample = ashaDoc.data();
    } catch (_) { /* ignore */ }

    if (existing.exists && existing.data()?.source === 'manual') {
      // prefer manual; do not overwrite the manual doc, but use it for risk calc with updated rainfall
      payload = { ...existing.data(), rainfall_mm };
    } else {
      let bias = biases[v.id];
      if (!bias) {
        bias = decideBias(v.id, now, rainfall_mm);
      }
      if (ashaSample && (ashaSample.ph || ashaSample.turbidity || typeof ashaSample.ecoli === 'boolean')) {
        payload = {
          timestamp: now.toISO(),
          ph: Number(ashaSample.ph ?? 0),
          turbidity: Number(ashaSample.turbidity ?? 0),
          ecoli: !!ashaSample.ecoli,
          rainfall_mm,
          daily_cases,
          source: 'asha',
          createdAt: Timestamp.fromDate(now.toJSDate()),
        };
      } else {
        const gen = bias ? generateBiased(String(bias).toLowerCase(), rainfall_mm) : generateAll(rainfall_mm);
        payload = {
          timestamp: now.toISO(),
          ph: gen.ph,
          turbidity: gen.turbidity,
          ecoli: gen.ecoli,
          rainfall_mm,
          daily_cases,
          source: 'generator',
          createdAt: Timestamp.fromDate(now.toJSDate()),
        };
      }
      await hourlyRef.set(payload, { merge: true });
    }

    // evaluate instantaneous risk
    const { risk, score, reasons } = evaluateHourly({
      ph: Number(payload.ph),
      turbidity: Number(payload.turbidity),
      ecoli: !!payload.ecoli,
      rainfall_mm: Number(payload.rainfall_mm),
      daily_cases: Number(payload.daily_cases ?? daily_cases),
      timestamp: payload.timestamp,
    });

    // Smooth/hysteresis: compute average of last 4 hours + current
    let adjustedRisk = risk;
    try {
      const recent = await base
        .collection('hourly')
        .orderBy('timestamp', 'desc')
        .limit(5)
        .get();
      const samples = [];
      recent.docs.forEach(d => {
        const v = d.data();
        const rEval = evaluateHourly({
          ph: Number(v.ph || 0),
          turbidity: Number(v.turbidity || 0),
          ecoli: !!v.ecoli,
          rainfall_mm: Number(v.rainfall_mm || 0),
          daily_cases: Number(v.daily_cases || 0),
        });
        samples.push(rEval.score);
      });
      if (samples.length) {
        const avgScore = samples.reduce((a,b)=>a+b,0)/samples.length;
        const hasCases = Number(payload.daily_cases || 0) > 0;
        // Never downgrade when there are reported cases
        if (!hasCases) {
          // downgrade RED if recent avg is low and current harsh factors absent
          if (risk === 'RED' && avgScore < 5 && !payload.ecoli && Number(payload.turbidity) <= 5 && Number(payload.rainfall_mm) <= 20) {
            adjustedRisk = 'YELLOW';
          }
          // downgrade YELLOW if recent avg is very low and current is mild
          if (adjustedRisk === 'YELLOW' && avgScore <= 2 && !payload.ecoli && Number(payload.turbidity) < 1 && Number(payload.rainfall_mm) < 5) {
            adjustedRisk = 'GREEN';
          }
        }
      }
    } catch (_) { /* ignore smoothing errors */ }

    await base.collection('status').doc('current_risk').set({
      risk: adjustedRisk,
      rawRisk: risk,
      score,
      reason: reasons,
      lastUpdated: now.toISO(),
    }, { merge: true });

    // ensure village meta exists on the village doc
    await base.set({
      name: v.name, district: v.district, state: v.state, lat: v.lat, lon: v.lon,
    }, { merge: true });
  }
}
