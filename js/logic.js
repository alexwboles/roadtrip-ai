/* RoadTrip AI — trip math. Pure functions, testable in Node. */

function estimateFuel(opts) {
  const roundTrip = !!(opts && opts.roundTrip);
  const oneWay = Math.max(0, parseFloat((opts && opts.distanceMi) || 0) || 0);
  const distanceMi = oneWay * (roundTrip ? 2 : 1);
  const mpg = Math.max(1, parseFloat((opts && opts.mpg) || 25) || 25);
  const gasPrice = Math.max(0, parseFloat((opts && opts.gasPrice) || 0) || 0);
  const gallons = distanceMi / mpg;
  const cost = gallons * gasPrice;
  return {
    distanceMi: distanceMi, oneWayMi: oneWay, roundTrip: roundTrip,
    mpg: mpg, gasPrice: gasPrice,
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

// Move a waypoint within the stop list (for up/down reorder buttons).
function reorderStop(stops, from, to) {
  const arr = (stops || []).slice();
  from = parseInt(from, 10); to = parseInt(to, 10);
  if (isNaN(from) || isNaN(to) || from === to) return arr;
  if (from < 0 || from >= arr.length || to < 0 || to >= arr.length) return arr;
  const moved = arr.splice(from, 1)[0];
  arr.splice(to, 0, moved);
  return arr;
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

// Average driving hours per day across the trip.
function dailyDriveHours(distanceMi, days, avgMph) {
  const d = Math.max(1, parseInt(days, 10) || 1);
  return Math.round(driveTimeHours(distanceMi, avgMph) / d * 10) / 10;
}

// Refuel stops needed, assuming you start with a full tank.
function fillUps(gallons, tankGal) {
  const g = Math.max(0, parseFloat(gallons) || 0);
  const t = Math.max(1, parseFloat(tankGal) || 12);
  if (g <= 0) return 0;
  return Math.ceil(g / t);
}

// Plain-text trip summary for copy-to-clipboard / sharing.
function tripSummaryText(o) {
  o = o || {};
  const money = (n) => "$" + (Math.round(n * 100) / 100).toFixed(2);
  const lines = [];
  const route = [o.origin, o.destination].filter(Boolean).join(" → ");
  lines.push((o.name || "My road trip") + (route ? " — " + route : ""));
  lines.push("Distance: " + (o.distanceMi || 0) + " mi" + (o.roundTrip ? " (round trip)" : "") +
    " · drive time ~" + (o.driveHours || 0) + " h (~" + (o.dailyDriveHours || 0) + " h/day)");
  lines.push("Fuel: " + (o.gallons || 0) + " gal (" + money(o.fuelCost || 0) + ", ~" + (o.fillUps || 0) + " fill-up(s))");
  lines.push("Budget: lodging " + money(o.lodging || 0) + " + food " + money(o.food || 0) +
    " + activities " + money(o.activities || 0) + " = " + money(o.total || 0) +
    " (" + money(o.perDay || 0) + "/day over " + (o.days || 1) + " days)");
  (o.itinerary || []).forEach(function (d) {
    const stops = d.stops.map(function (s) { return s.name + (s.notes ? " (" + s.notes + ")" : ""); }).join("; ");
    lines.push("Day " + d.day + ": " + (stops || "open road"));
  });
  return lines.join("\n");
}

// Road-trip car essentials — the "packing tie-in" checklist.
const CAR_ESSENTIALS = [
  "Spare tire + jack", "Jumper cables", "Phone charger / car adapter",
  "Snacks & water", "First-aid kit", "Paper maps (backup)",
  "Sunglasses", "Trash bags", "Blanket", "Flashlight"
];

if (typeof module !== "undefined" && module.exports) {
  module.exports = { estimateFuel, buildItinerary, reorderStop, budgetSummary, perDayCost, driveTimeHours, dailyDriveHours, fillUps, tripSummaryText, CAR_ESSENTIALS };
}
