// Random generator for pH, turbidity, ecoli per spec (seasonal-aware)
import { isMonsoon, isMonsoonEvening } from './config/season.js';

function uniform(min, max) {
  return min + Math.random() * (max - min);
}

// Backward compatibility: generateAll(rainfall_mm [, now])
export function generateAll(rainfall_mm = 0, now = new Date()) {
  const { ph, turbidity, ecoli } = generateAllSeasonal(now, rainfall_mm);
  return { ph, turbidity, ecoli };
}

export function generatePH() {
  const r = Math.random();
  if (r < 0.85) return Number(uniform(6.5, 8.5).toFixed(2));
  if (r < 0.95) {
    // 10% slight deviations
    return Math.random() < 0.5
      ? Number(uniform(6.0, 6.49).toFixed(2))
      : Number(uniform(8.51, 9.0).toFixed(2));
  }
  // 5% heavy deviations
  return Math.random() < 0.5
    ? Number(uniform(4.5, 5.99).toFixed(2))
    : Number(uniform(9.01, 10.5).toFixed(2));
}

export function generateTurbidity() {
  const r = Math.random();
  if (r < 0.7) return Number(uniform(0.1, 1.0).toFixed(2));
  if (r < 0.9) return Number(uniform(1.1, 5.0).toFixed(2));
  return Number(uniform(5.1, 50.0).toFixed(2));
}

export function generateEcoli({ ph, turbidity, rainfall_mm }) {
  let baseProb = 0.01;
  if (turbidity > 5) baseProb += 0.10;
  if (rainfall_mm > 10) baseProb += 0.05;
  if (ph < 6.5 || ph > 8.5) baseProb += 0.02;
  return Math.random() < baseProb;
}

// Seasonal defaults + nudges
function generatePHSeasonal(now) {
  const monsoon = isMonsoon(now);
  let safe = 0.85;
  let slight = 0.10;
  let severe = 0.05;
  if (monsoon) {
    safe = Math.max(0, safe - 0.08);    // 0.77
    slight = 0.10;                       // unchanged
    severe = 1 - safe - slight;          // 0.13
  }
  const r = Math.random();
  if (r < safe) return Number(uniform(6.5, 8.5).toFixed(2));
  if (r < safe + slight) {
    return Math.random() < 0.5
      ? Number(uniform(6.0, 6.49).toFixed(2))
      : Number(uniform(8.51, 9.0).toFixed(2));
  }
  return Math.random() < 0.5
    ? Number(uniform(4.5, 5.99).toFixed(2))
    : Number(uniform(9.01, 10.5).toFixed(2));
}

function generateTurbiditySeasonal(now) {
  const monsoon = isMonsoon(now);
  const evening = isMonsoonEvening(now);
  // base buckets: 70% <1, 20% 1–5, 10% >5
  let b1 = 0.70, b2 = 0.20, b3 = 0.10;
  if (monsoon) {
    b3 += 0.08; // 0.18
    b1 = Math.max(0, b1 - 0.06); // 0.64
    b2 = 1 - b1 - b3;            // 0.18
  }
  if (monsoon && evening) {
    // further bias to higher NTU in monsoon evenings
    const shift = 0.05;
    b1 = Math.max(0, b1 - shift);
    b3 = Math.min(0.99, b3 + shift * 0.6);
    b2 = 1 - b1 - b3;
  }
  const r = Math.random();
  if (r < b1) return Number(uniform(0.1, 1.0).toFixed(2));
  if (r < b1 + b2) return Number(uniform(1.1, 5.0).toFixed(2));
  return Number(uniform(5.1, 50.0).toFixed(2));
}

export function generateAllSeasonal(now, baseRainfallMm) {
  // Apply rainfall multiplier
  const monsoon = isMonsoon(now);
  const evening = isMonsoonEvening(now);
  let multiplier = 1.0;
  if (monsoon) multiplier *= 1.4;
  const rainfall_mm = Number((baseRainfallMm * multiplier).toFixed(2));

  const ph = generatePHSeasonal(now);
  const turbidity = generateTurbiditySeasonal(now);

  // E. coli probability baseline
  let ecoliBase = 0.01;
  if (monsoon) ecoliBase += 0.03;        // 0.04
  if (monsoon && evening) ecoliBase += 0.05;
  // risk adders
  if (turbidity > 5) ecoliBase += 0.10;
  if (rainfall_mm > 10) ecoliBase += 0.05;
  if (ph < 6.5 || ph > 8.5) ecoliBase += 0.02;
  const ecoli = Math.random() < ecoliBase;

  return { ph, turbidity, ecoli, rainfall_mm };
}

export function generateBiased(bias = 'green', rainfall_mm = 0) {
  let ph, turbidity, ecoli;
  if (bias === 'red') {
    // push outside safe ranges
    turbidity = Number((5.5 + Math.random() * 20).toFixed(2));
    ph = Math.random() < 0.5 ? Number((5.2 + Math.random() * 0.7).toFixed(2)) : Number((9.1 + Math.random() * 1.0).toFixed(2));
    const base = 0.25 + (turbidity > 10 ? 0.25 : 0) + (rainfall_mm > 10 ? 0.1 : 0);
    ecoli = Math.random() < base;
  } else if (bias === 'yellow') {
    turbidity = Number((1.2 + Math.random() * 3.5).toFixed(2));
    // slight pH deviation sometimes
    ph = Math.random() < 0.4 ? (Math.random() < 0.5 ? Number((6.1 + Math.random() * 0.3).toFixed(2)) : Number((8.6 + Math.random() * 0.3).toFixed(2))) : Number((6.6 + Math.random() * 1.6).toFixed(2));
    const base = 0.05 + (turbidity > 3 ? 0.08 : 0) + (rainfall_mm > 10 ? 0.05 : 0);
    ecoli = Math.random() < base;
  } else {
    // green
    turbidity = Number((0.2 + Math.random() * 0.7).toFixed(2));
    ph = Number((6.7 + Math.random() * 1.3).toFixed(2));
    const base = 0.01 + (rainfall_mm > 10 ? 0.03 : 0);
    ecoli = Math.random() < base;
  }
  return { ph, turbidity, ecoli };
}
