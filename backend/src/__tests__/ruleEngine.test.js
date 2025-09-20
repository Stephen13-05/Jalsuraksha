import { evaluateHourly, evaluateDaily } from '../ruleEngine.js';

test('hourly risk GREEN baseline', () => {
  const r = evaluateHourly({ ph: 7.2, turbidity: 0.5, ecoli: false, rainfall_mm: 0, daily_cases: 0 });
  expect(r.risk).toBe('GREEN');
});

test('hourly risk RED for ecoli + turbidity', () => {
  const r = evaluateHourly({ ph: 7.2, turbidity: 6, ecoli: true, rainfall_mm: 0, daily_cases: 0 });
  expect(r.risk).toBe('RED');
});

test('daily risk thresholds rainfall', () => {
  const r = evaluateDaily({ avg_ph: 7.0, avg_turbidity: 0.8, ecoli_present: false, rainfall_total_mm: 60, daily_cases: 0 });
  expect(r.risk).toBe('YELLOW' /* score 2 rainfall only */ || 'RED');
});
