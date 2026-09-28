#!/usr/bin/env bash
# RoadTrip AI smoke tests — 12 checks. Exit non-zero on first failure.
set -u
cd "$(dirname "$0")/.."
pass=0; fail=0
check() { # $1 = description, rest = command
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "PASS: $desc"; pass=$((pass+1));
  else echo "FAIL: $desc"; fail=$((fail+1)); fi
}

check "index.html exists" test -f index.html
check "css/style.css exists" test -f css/style.css
check "js/logic.js exists" test -f js/logic.js
check "js/app.js exists" test -f js/app.js
check "logic.js syntax valid" node --check js/logic.js
check "app.js syntax valid" node --check js/app.js
check "logic exports all functions" node -e "
  const L=require('./js/logic.js');
  for (const f of ['estimateFuel','buildItinerary','budgetSummary','perDayCost','driveTimeHours']) {
    if(typeof L[f]!=='function') throw new Error('missing '+f);
  }"
check "fuel math: 500mi/25mpg@\$4 = 20gal/\$80" node -e "
  const L=require('./js/logic.js');
  const f=L.estimateFuel({distanceMi:500,mpg:25,gasPrice:4});
  if(f.gallons!==20||f.cost!==80) throw new Error(JSON.stringify(f));"
check "budget totals add up" node -e "
  const L=require('./js/logic.js');
  const b=L.budgetSummary({fuelCost:80,lodgingPerNight:100,nights:3,foodPerDay:50,days:4,activitiesCost:60});
  if(b.total!==80+300+200+60) throw new Error('total='+b.total);"
check "itinerary distributes 5 stops over 2 days" node -e "
  const L=require('./js/logic.js');
  const p=L.buildItinerary({days:2,stops:[{name:'a'},{name:'b'},{name:'c'},{name:'d'},{name:'e'}]});
  if(p.length!==2||p[0].stops.length!==3||p[1].stops.length!==2) throw new Error(JSON.stringify(p.map(x=>x.stops.length)));"
check "perDayCost divides correctly" node -e "
  const L=require('./js/logic.js');
  if(L.perDayCost(640,4)!==160) throw new Error('bad per-day');"
check "CAR_ESSENTIALS has 10 items" node -e "
  const L=require('./js/logic.js');
  if(!Array.isArray(L.CAR_ESSENTIALS)||L.CAR_ESSENTIALS.length!==10) throw new Error('bad essentials');"

echo "--- smoke: $pass passed, $fail failed ---"
exit $((fail>0))
