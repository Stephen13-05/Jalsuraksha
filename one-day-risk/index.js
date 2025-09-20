import dotenv from 'dotenv';
import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import { DateTime } from 'luxon';
const villages = JSON.parse(readFileSync(new URL('../backend/src/config/villages.json', import.meta.url), 'utf8'));

dotenv.config();

const TZ = process.env.TIMEZONE || 'Asia/Kolkata';
const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

const sa = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));
admin.initializeApp({ credential: admin.credential.cert(sa) });
const firestore = admin.firestore();

async function main() {
  const date = process.argv[2] || DateTime.now().setZone(TZ).toISODate();
  const startISO = DateTime.fromISO(date, { zone: TZ }).toUTC().toISO({ suppressMilliseconds: true });
  const endISO = DateTime.fromISO(date, { zone: TZ }).plus({ days: 1 }).toUTC().toISO({ suppressMilliseconds: true });

  for (const v of villages) {
    const base = firestore.collection('appdata').doc('main').collection('villages').doc(v.id);
    const qSnap = await base
      .collection('hourly')
      .where('timestamp', '>=', startISO)
      .where('timestamp', '<', endISO)
      .get();
    console.log(v.id, date, qSnap.size);
  }
}

main().then(()=>process.exit(0));
