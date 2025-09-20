// Rule engine scoring
import { isMonsoonEvening } from './config/season.js';

function pushReason(reasons, cond, text) {
  if (cond) reasons.push(text);
}

export function evaluateHourly({ ph, turbidity, ecoli, rainfall_mm, daily_cases, timestamp }) {
  let score = 0;
  const reasons = [];

  // pH
  if (ph < 6.5 || ph > 8.5) {
    score += 2;
    pushReason(reasons, true, 'pH out of 6.5-8.5');
  } else if ((ph >= 6.0 && ph <= 6.49) || (ph >= 8.51 && ph <= 9.0)) {
    score += 1;
    pushReason(reasons, true, 'pH slight deviation');
  }

  // turbidity
  if (turbidity > 5) { score += 2; pushReason(reasons, true, 'turbidity > 5'); }
  else if (turbidity >= 1.0) { score += 1; pushReason(reasons, true, 'turbidity 1-5'); }

  // ecoli
  if (ecoli) { score += 3; pushReason(reasons, true, 'E. coli present'); }

  // rainfall (this hour)
  if (rainfall_mm > 20) { score += 2; pushReason(reasons, true, 'rainfall > 20mm'); }
  else if (rainfall_mm >= 5) { score += 1; pushReason(reasons, true, 'rainfall 5-20mm'); }

  // daily cases (consolidated) — any non-zero cases should push to at least YELLOW
  if (daily_cases >= 10) { score += 5; pushReason(reasons, true, 'daily cases >= 10'); }
  else if (daily_cases >= 4) { score += 4; pushReason(reasons, true, 'daily cases 4-9'); }
  else if (daily_cases >= 1) { score += 3; pushReason(reasons, true, 'daily cases 1-3'); }

  // seasonal bump: monsoon evenings
  if (timestamp && isMonsoonEvening(timestamp)) {
    score += 1;
    pushReason(reasons, true, 'monsoon evening bump');
  }

  const risk = score >= 5 ? 'RED' : score >= 3 ? 'YELLOW' : 'GREEN';
  return { risk, score, reasons };
}

export function evaluateDaily({ avg_ph, avg_turbidity, ecoli_present, rainfall_total_mm, daily_cases }) {
  let score = 0;
  const reasons = [];

  // Use same logic but with rainfall thresholds adjusted
  if (avg_ph < 6.5 || avg_ph > 8.5) { score += 2; pushReason(reasons, true, 'avg pH out of 6.5-8.5'); }
  else if ((avg_ph >= 6.0 && avg_ph <= 6.49) || (avg_ph >= 8.51 && avg_ph <= 9.0)) { score += 1; pushReason(reasons, true, 'avg pH slight deviation'); }

  if (avg_turbidity > 5) { score += 2; pushReason(reasons, true, 'avg turbidity > 5'); }
  else if (avg_turbidity >= 1.0) { score += 1; pushReason(reasons, true, 'avg turbidity 1-5'); }

  if (ecoli_present) { score += 3; pushReason(reasons, true, 'E. coli present'); }

  if (rainfall_total_mm > 50) { score += 2; pushReason(reasons, true, 'rainfall > 50mm'); }
  else if (rainfall_total_mm >= 20) { score += 1; pushReason(reasons, true, 'rainfall 20-50mm'); }

  if (daily_cases >= 10) { score += 3; pushReason(reasons, true, 'daily cases >= 10'); }
  else if (daily_cases >= 4) { score += 2; pushReason(reasons, true, 'daily cases 4-9'); }
  else if (daily_cases >= 1) { score += 1; pushReason(reasons, true, 'daily cases 1-3'); }

  const risk = score >= 5 ? 'RED' : score >= 3 ? 'YELLOW' : 'GREEN';
  return { risk, score, reasons };
}

export default { evaluateHourly, evaluateDaily };
