#!/usr/bin/env bash
# RoadTrip AI e2e tests — 6 flows exercising real logic in Node. Exit non-zero on failure.
set -u
cd "$(dirname "$0")/.."
pass=0; fail=0
flow() { # $1 = description, $2 = node script
  if node -e "$2" >/dev/null 2>&1; then echo "PASS: $1"; pass=$((pass+1));
  else echo "FAIL: $1"; fail=$((fail+1)); fi
}

flow "full trip: 1200mi/30mpg@\$3.50 fuel = \$140" "
  const L=require('./js/logic.js');
  const f=L.estimateFuel({distanceMi:1200,mpg:30,gasPrice:3.5});
  if(f.gallons!==40||f.cost!==140) throw new Error(JSON.stringify(f));"

flow "zero mpg guard does not divide by zero" "
  const L=require('./js/logic.js');
  const f=L.estimateFuel({distanceMi:100,mpg:0,gasPrice:4});
  if(!isFinite(f.gallons)||!isFinite(f.cost)) throw new Error('infinite: '+JSON.stringify(f));"

flow "itinerary keeps stop notes attached to days" "
  const L=require('./js/logic.js');
  const p=L.buildItinerary({days:3,stops:[{name:'GC',notes:'sunrise'},{name:'Vegas'}]});
  if(p[0].stops[0].notes!=='sunrise') throw new Error('notes lost');
  if(p[2].stops.length!==0) throw new Error('day 3 should be open road');"

flow "budget with zero nights drops lodging" "
  const L=require('./js/logic.js');
  const b=L.budgetSummary({fuelCost:50,lodgingPerNight:120,nights:0,foodPerDay:40,days:2,activitiesCost:0});
  if(b.lodging!==0||b.total!==50+0+80+0) throw new Error(JSON.stringify(b));"

flow "drive time: 550mi at default 55mph = 10h" "
  const L=require('./js/logic.js');
  if(L.driveTimeHours(550)!==10) throw new Error('bad drive time');"

flow "per-day cost rounds to cents" "
  const L=require('./js/logic.js');
  if(L.perDayCost(100,3)!==33.33) throw new Error('bad rounding: '+L.perDayCost(100,3));"

echo "--- e2e: $pass passed, $fail failed ---"
exit $((fail>0))
