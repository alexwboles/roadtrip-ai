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
check "logic exports new functions" node -e "
  const L=require('./js/logic.js');
  for (const f of ['reorderStop','dailyDriveHours','fillUps','tripSummaryText']) {
    if(typeof L[f]!=='function') throw new Error('missing '+f);
  }"
check "round trip doubles distance and fuel" node -e "
  const L=require('./js/logic.js');
  const f=L.estimateFuel({distanceMi:500,mpg:25,gasPrice:4,roundTrip:true});
  if(f.distanceMi!==1000||f.oneWayMi!==500||f.gallons!==40||f.cost!==160||f.roundTrip!==true) throw new Error(JSON.stringify(f));
  const one=L.estimateFuel({distanceMi:500,mpg:25,gasPrice:4});
  if(one.distanceMi!==500||one.roundTrip!==false) throw new Error('one-way broken: '+JSON.stringify(one));"
check "reorderStop moves waypoints, bad indexes no-op" node -e "
  const L=require('./js/logic.js');
  const r=L.reorderStop([{name:'a'},{name:'b'},{name:'c'}],0,2);
  if(r.map(x=>x.name).join('')!=='bca') throw new Error(JSON.stringify(r.map(x=>x.name)));
  const d=L.reorderStop([{name:'a'},{name:'b'},{name:'c'}],2,0);
  if(d.map(x=>x.name).join('')!=='cab') throw new Error('down move');
  const bad=L.reorderStop([{name:'a'}],0,5);
  if(bad.length!==1||bad[0].name!=='a') throw new Error('out-of-range should be no-op');"
check "daily drive time + fill-ups math" node -e "
  const L=require('./js/logic.js');
  if(L.dailyDriveHours(550,2)!==5) throw new Error('daily drive: '+L.dailyDriveHours(550,2));
  if(L.dailyDriveHours(550)!==10) throw new Error('single day default');
  if(L.fillUps(20,12)!==2) throw new Error('fillups 20/12');
  if(L.fillUps(12,12)!==1) throw new Error('exact tank');
  if(L.fillUps(0,12)!==0) throw new Error('zero gallons');"
check "tripSummaryText builds shareable text" node -e "
  const L=require('./js/logic.js');
  const t=L.tripSummaryText({name:'Desert run',origin:'Phoenix',destination:'Moab',roundTrip:true,distanceMi:1000,driveHours:18,dailyDriveHours:9,gallons:40,fuelCost:140,fillUps:4,lodging:300,food:200,activities:60,total:700,perDay:175,days:4,itinerary:[{day:1,stops:[{name:'GC',notes:'sunrise'}]},{day:2,stops:[]}]});
  if(!/Desert run — Phoenix → Moab/.test(t)) throw new Error('header: '+t.split('\n')[0]);
  if(!/round trip/.test(t)) throw new Error('roundtrip flag');
  if(!/Day 1: GC \(sunrise\)/.test(t)) throw new Error('day1 stops');
  if(!/Day 2: open road/.test(t)) throw new Error('day2 empty');
  if(!/\\\$700\\.00/.test(t)) throw new Error('total money');"
check "new UI wiring present" bash -c "
  grep -q 'id=\"roundTrip\"' index.html && grep -q 'id=\"tankGal\"' index.html &&
  grep -q 'copySummary' js/app.js && grep -q 'data-wpup' js/app.js &&
  grep -q 'data-wpdn' js/app.js && grep -q 'tripSummaryText' js/app.js &&
  grep -q 'dailyDriveHours' js/app.js && grep -q 'wp-btns' css/style.css"

echo "--- smoke: $pass passed, $fail failed ---"
exit $((fail>0))
