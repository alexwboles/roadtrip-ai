# RoadTrip AI — Redesign Audit (2026-10-13)

Competitors researched: **Roadtrippers** (visual route timeline, day-by-day itinerary with stops pinned to days, drive-time awareness).

## Visual gaps vs competitors
1. The day-by-day itinerary was flat text cards — Roadtrippers renders the journey as a **route**: a vertical timeline with day nodes, so you see the trip unfold.
2. Per-day effort (drive vs. visit hours) was a text line; a visual **day bar** (drive share + visit share against the day budget) reads instantly.

## Functional gaps vs competitors
1. Overpacked days were flagged in text only — the bar makes them visible.
2. (Kept as-is, already strong: fuel math, fill-ups, budget breakdown, day-load report, packing checklist, copy/print, saved trips, round trip.)

## Redesign plan
- **Route-timeline itinerary**: vertical route line with numbered day nodes, date chips, per-day drive/visit bar against the 12h budget, stops listed under each day, overloaded days get a rust node + "overpacked" tag.
- All data already computed (`itineraryWithDates`, `dayLoadReport`) — pure presentation upgrade, zero logic risk.
- All existing features preserved: expedition brief, waypoints (add/reorder/remove), plan/drive math, budget, packing checklist, copy summary, print, saved trips.

## Concept (1 paragraph)
Keep "The Open Road Atlas" identity (deep pine header, sand canvas, atlas teal) but draw the itinerary like Roadtrippers draws a route: the day-by-day becomes a vertical timeline with numbered waypoints, each day carrying a drive/visit effort bar — so the plan reads as a journey, not a spreadsheet.
