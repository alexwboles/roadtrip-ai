/* RoadTrip AI — trip math. Pure functions, testable in Node. */

function estimateFuel(opts) {
  const distanceMi = Math.max(0, parseFloat((opts && opts.distanceMi) || 0) || 0);
  const mpg = Math.max(1, parseFloat((opts && opts.mpg) || 25) || 25);
  const gasPrice = Math.max(0, parseFloat((opts && opts.gasPrice) || 0) || 0);
  const gallons = distanceMi / mpg;
  const cost = gallons * gasPrice;
  return {
    distanceMi: distanceMi, mpg: mpg, gasPrice: gasPrice,
    gallons: Math.round(gallons * 10) / 10,
    cost: Math.round(cost * 100) / 100
  };
}

function buildItinerary(opts) {
  const days = Math.max(1, Math.min(60, parseInt((opts && opts.days) || 1, 10) || 1));
  const stops = (opts && opts.stops) || [];
  const plan = [];
  for (let d = 1; d <= days; d++) plan.push({ day: d, stops: [] });
  stops.forEach((s, i) => { plan[i % days].stops.push(s); });
  return plan;
}

function budgetSummary(opts) {
  const o = opts || {};
  const fuel = Math.max(0, parseFloat(o.fuelCost) || 0);
  const lodging = Math.max(0, parseFloat(o.lodgingPerNight) || 0) * Math.max(0, parseInt(o.nights, 10) || 0);
  const food = Math.max(0, parseFloat(o.foodPerDay) || 0) * Math.max(0, parseInt(o.days, 10) || 0);
  const activities = Math.max(0, parseFloat(o.activitiesCost) || 0);
  const total = fuel + lodging + food + activities;
  const r2 = (n) => Math.round(n * 100) / 100;
  return { fuel: r2(fuel), lodging: r2(lodging), food: r2(food), activities: r2(activities), total: r2(total) };
}

function perDayCost(total, days) {
  const d = Math.max(1, parseInt(days, 10) || 1);
  return Math.round((parseFloat(total) || 0) / d * 100) / 100;
}

function driveTimeHours(distanceMi, avgMph) {
  const mph = Math.max(1, parseFloat(avgMph) || 55);
  const h = (Math.max(0, parseFloat(distanceMi) || 0)) / mph;
  return Math.round(h * 10) / 10;
}

// Road-trip car essentials — the "packing tie-in" checklist.
const CAR_ESSENTIALS = [
  "Spare tire + jack", "Jumper cables", "Phone charger / car adapter",
  "Snacks & water", "First-aid kit", "Paper maps (backup)",
  "Sunglasses", "Trash bags", "Blanket", "Flashlight"
];

if (typeof module !== "undefined" && module.exports) {
  module.exports = { estimateFuel, buildItinerary, budgetSummary, perDayCost, driveTimeHours, CAR_ESSENTIALS };
}
