# 🚗 RoadTrip AI

Road trip planner: day-by-day itinerary builder, fuel cost estimator, and full trip budget summary.

**100% local.** No account, no API keys, no network calls. Your trips never leave the browser (saved in localStorage).

## Features

- Origin → destination + unlimited waypoints with notes
- Day-by-day itinerary (stops auto-distributed across days)
- Fuel cost estimator (distance, MPG, gas price → gallons + cost)
- Drive-time estimate at average highway speed
- Full budget summary: fuel, lodging, food, activities + per-day cost
- Car packing checklist (persists separately)
- Named saved trips with reload
- Packing tie-in: pairs with TravelPack AI for the full suitcase list

## Run it

Just open `index.html` in a browser — no build step. Or serve locally:

```bash
npx serve .
# or
python3 -m http.server 8080
```

## Tests

```bash
bash test/smoke.sh   # 12 checks
bash test/e2e.sh     # 6 flows
```

## How it works

`js/logic.js` holds all trip math (fuel, itinerary distribution, budget) as pure functions,
fully unit-tested in Node. `js/app.js` wires the UI. No API keys required — everything
computes locally.

## License

MIT
