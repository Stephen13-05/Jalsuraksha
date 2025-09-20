// Seasonal configuration and helpers
export const MONSOON_MONTHS = [6, 7, 8, 9]; // Jun–Sep
export const EVENING_HOURS = [18, 19, 20, 21, 22, 23];

export function isMonsoon(dt) {
  // dt: Luxon DateTime or JS Date or ISO string
  const month = getMonth(dt);
  return MONSOON_MONTHS.includes(month);
}

export function isMonsoonEvening(dt) {
  const month = getMonth(dt);
  const hour = getHour(dt);
  return MONSOON_MONTHS.includes(month) && EVENING_HOURS.includes(hour);
}

function getMonth(dt) {
  if (!dt) return new Date().getMonth() + 1;
  if (typeof dt === 'string') {
    const d = new Date(dt);
    return (d.getMonth() + 1);
  }
  // Luxon DateTime has .month
  if (typeof dt.month === 'number') return dt.month;
  if (dt instanceof Date) return dt.getMonth() + 1;
  return new Date().getMonth() + 1;
}

function getHour(dt) {
  if (!dt) return new Date().getHours();
  if (typeof dt === 'string') {
    const d = new Date(dt);
    return d.getHours();
  }
  if (typeof dt.hour === 'number') return dt.hour;
  if (dt instanceof Date) return dt.getHours();
  return new Date().getHours();
}
