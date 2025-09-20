import { DateTime } from 'luxon';
import { firestore, TZ, Timestamp } from '../config/index.js';
import { readFileSync } from 'fs';
const villages = JSON.parse(readFileSync(new URL('../config/villages.json', import.meta.url), 'utf8'));
import { evaluateDaily } from '../ruleEngine.js';
import { computeDailyCases } from './hourlyJob.js';

export async function runDaily(dateStr) {
  if (!firestore) throw new Error('Firestore not initialized');
  const now = DateTime.now().setZone(TZ);
  const targetDate = dateStr || now.toISODate();

  const start = DateTime.fromISO(targetDate, { zone: TZ });
  const end = DateTime.fromISO(targetDate, { zone: TZ }).plus({ days: 1 });
  const startISO = start.toUTC().toISO({ suppressMilliseconds: true });
  const endISO = end.toUTC().toISO({ suppressMilliseconds: true });

  for (const v of villages) {
    const base = firestore.collection('appdata').doc('main').collection('villages').doc(v.id);

    // Fetch hourly docs for the date by timestamp string range (ISO lexicographic)
    const qSnap = await base
      .collection('hourly')
      .where('timestamp', '>=', startISO)
      .where('timestamp', '<', endISO)
      .get();

    const entries = qSnap.docs.map(d => d.data());

    if (entries.length === 0) {
      await base.collection('daily').doc(targetDate).set({
        avg_ph: 0, avg_turbidity: 0, rainfall_total_mm: 0, ecoli_present: false,
        daily_cases: 0, final_daily_risk: 'GREEN', createdAt: now.toISO(),
      }, { merge: true });
      continue;
    }

    const avg = (arr) => arr.reduce((a,b)=>a+b,0) / (arr.length || 1);
    const phs = entries.map(e => Number(e.ph || 0));
    const turbs = entries.map(e => Number(e.turbidity || 0));
    const rains = entries.map(e => Number(e.rainfall_mm || 0));
    const ecolis = entries.map(e => !!e.ecoli);

    const avg_ph = Number(avg(phs).toFixed(2));
    const avg_turbidity = Number(avg(turbs).toFixed(2));
    const rainfall_total_mm = Number(rains.reduce((a,b)=>a+b,0).toFixed(2));
    const ecoli_present = ecolis.some(Boolean);

    // Prefer consolidated daily counter; else fallback to computing from reports for this date
    let daily_cases = 0;
    try {
      const casesDoc = await firestore
        .collection('appdata')
        .doc('main')
        .collection('ashaworkers_daily_cases')
        .doc(targetDate)
        .collection('villages')
        .doc(v.id)
        .get();
      if (casesDoc.exists) {
        daily_cases = Number((casesDoc.data()?.count) || 0);
      } else {
        const { daily_cases: computed } = await computeDailyCases(v, start);
        daily_cases = Number(computed || 0);
      }
    } catch (_) {
      const { daily_cases: computed } = await computeDailyCases(v, start);
      daily_cases = Number(computed || 0);
    }

    const { risk, score, reasons } = evaluateDaily({ avg_ph, avg_turbidity, ecoli_present, rainfall_total_mm, daily_cases });

    await base.collection('daily').doc(targetDate).set({
      avg_ph, avg_turbidity, rainfall_total_mm, ecoli_present, daily_cases,
      final_daily_risk: risk, score, reason: reasons, createdAt: now.toISO(),
    }, { merge: true });

    // Sync consolidated daily cases counter for frontend aggregation cards
    try {
      await firestore
        .collection('appdata')
        .doc('main')
        .collection('ashaworkers_daily_cases')
        .doc(targetDate)
        .collection('villages')
        .doc(v.id)
        .set({ count: Number(daily_cases) || 0, updatedAt: now.toISO() }, { merge: true });
    } catch (_) { /* ignore */ }

    // delete hourly entries for that date
    const batch = firestore.batch();
    qSnap.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  }
}
