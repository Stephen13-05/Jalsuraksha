import dotenv from 'dotenv';
import admin from 'firebase-admin';
import { readFileSync } from 'fs';

dotenv.config();

export const TZ = process.env.TIMEZONE || 'Asia/Kolkata';
export const WEATHER_API_KEY = process.env.WEATHER_API_KEY || '';

const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

if (!serviceAccountPath) {
  console.warn('[config] Missing FIREBASE_SERVICE_ACCOUNT_PATH in env. Firebase will fail to init.');
}

let app;
let serviceAccount;
try {
  serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));
  app = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
} catch (e) {
  console.error('[firebase] Failed to initialize Admin SDK:', e.message);
}

export const firestore = app ? admin.firestore() : null;
export const Timestamp = admin.firestore.Timestamp;
export const ProjectId = serviceAccount?.project_id;
if (firestore && ProjectId) {
  console.log(`[firebase] Firestore initialized for project: ${ProjectId}`);
}
