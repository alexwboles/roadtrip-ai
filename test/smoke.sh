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
check "planDriveDays recommends more days over the limit" node -e "
  const L=require('./js/logic.js');
  const p=L.planDriveDays(1000,2,55,8);
  if(!p.over) throw new Error('1000mi/2d should be over an 8h limit');
  if(p.daysNeeded!==3) throw new Error('daysNeeded: '+p.daysNeeded);
  if(p.dailyDrive!==9.1) throw new Error('dailyDrive: '+p.dailyDrive);
  const ok=L.planDriveDays(1000,3,55,8);
  if(ok.over) throw new Error('3 days should fit');
  if(ok.daysNeeded!==3) throw new Error('daysNeeded fits');
  const zero=L.planDriveDays(0,2,55,8);
  if(zero.over||zero.daysNeeded!==1) throw new Error('zero distance');
  const def=L.planDriveDays(500,1);
  if(def.maxDailyHrs!==8) throw new Error('default 8h limit');"
check "itineraryWithDates stamps calendar dates" node -e "
  const L=require('./js/logic.js');
  const itin=L.itineraryWithDates([{day:1,stops:[]},{day:2,stops:[]},{day:3,stops:[]}],'2026-10-12');
  if(itin[0].date!=='Mon 10/12') throw new Error('day1: '+itin[0].date);
  if(itin[1].date!=='Tue 10/13') throw new Error('day2: '+itin[1].date);
  if(itin[2].iso!=='2026-10-14') throw new Error('iso: '+itin[2].iso);
  const blank=L.itineraryWithDates([{day:1,stops:[]}],'');
  if(blank[0].date!=='') throw new Error('blank start keeps empty date');
  const bad=L.itineraryWithDates([{day:1,stops:[]}],'not-a-date');
  if(bad[0].date!=='') throw new Error('bad date keeps empty date');"
check "dayLoadReport flags overpacked days" node -e "
  const L=require('./js/logic.js');
  const itin=[{day:1,date:'Mon 10/12',stops:[{name:'A',hoursAt:3},{name:'B',hoursAt:2}]},{day:2,date:'Tue 10/13',stops:[{name:'C'}]}];
  const r=L.dayLoadReport(itin,6,12);
  if(r[0].visitHrs!==5||r[0].totalHrs!==11||r[0].overloaded) throw new Error('day1: '+JSON.stringify(r[0]));
  if(r[1].visitHrs!==0||r[1].totalHrs!==6) throw new Error('day2: '+JSON.stringify(r[1]));
  const heavy=L.dayLoadReport([{day:1,stops:[{name:'A',hoursAt:8}]}],6,12);
  if(!heavy[0].overloaded) throw new Error('14h day should flag overloaded');"
check "tripSummaryText includes itinerary dates" node -e "
  const L=require('./js/logic.js');
  const t=L.tripSummaryText({name:'T',days:1,itinerary:[{day:1,date:'Mon 10/12',stops:[{name:'GC'}]}]});
  if(!/Day 1 \\(Mon 10\\/12\\): GC/.test(t)) throw new Error('dated day line: '+t);"
check "new UI wiring present" bash -c "
  grep -q 'id=\"roundTrip\"' index.html && grep -q 'id=\"tankGal\"' index.html &&
  grep -q 'copySummary' js/app.js && grep -q 'data-wpup' js/app.js &&
  grep -q 'data-wpdn' js/app.js && grep -q 'tripSummaryText' js/app.js &&
  grep -q 'dailyDriveHours' js/app.js && grep -q 'wp-btns' css/style.css &&
  grep -q 'id=\"startDate\"' index.html && grep -q 'id=\"maxDrive\"' index.html &&
  grep -q 'id=\"wpHours\"' index.html && grep -q 'planDriveDays' js/app.js &&
  grep -q 'itineraryWithDates' js/app.js && grep -q 'dayLoadReport' js/app.js &&
  grep -q 'fixDays' js/app.js && grep -q 'alert.warn' css/style.css"

check "avg-speed math: speed scales drive time" node -e "
  const L=require('./js/logic.js');
  const slow=L.planDriveDays(600,4,50,8), fast=L.planDriveDays(600,4,75,8);
  if(slow.driveHours!==12||fast.driveHours!==8) throw new Error('speed must scale drive time');
  if(slow.dailyDrive!==3||fast.dailyDrive!==2) throw new Error('per-day must scale');"
check "avgSpeed input wired into app" bash -c "
  grep -q 'id=\"avgSpeed\"' index.html &&
  grep -q 'printItin' js/app.js && grep -q 'fallbackCopy' js/app.js &&
  grep -q '@media print' css/style.css &&
  grep -q 'no-print' css/style.css"

check "route timeline in app.js" grep -q "class='route'" js/app.js
check "day nodes in app.js" grep -q "rdot" js/app.js
check "day effort bars in app.js" grep -q "daybar" js/app.js
check "route CSS present" grep -q ".rday" css/style.css
check "itinerary day-load math" node -e "
  const L = require('./js/logic.js');
  const itin = L.itineraryWithDates(L.buildItinerary({ days: 4, stops: [ { name: 'A', hoursAt: 3 }, { name: 'B', hoursAt: 2 }, { name: 'C', hoursAt: 1 } ] }), '2026-11-03');
  if (itin.length !== 4 || itin[0].date !== 'Tue 11/3') throw new Error('dates: ' + JSON.stringify(itin.map(d => d.date)));
  const loads = L.dayLoadReport(itin, 5.5, 12);
  if (loads[0].visitHrs !== 3 || loads[0].totalHrs !== 8.5) throw new Error('day1 load: ' + JSON.stringify(loads[0]));
  if (loads[3].visitHrs !== 0 || loads[3].totalHrs !== 5.5) throw new Error('day4 load');
  if (loads.some(l => l.overloaded)) throw new Error('nothing should be overloaded');
  const heavy = L.dayLoadReport(itin, 11, 12);
  if (!heavy[0].overloaded) throw new Error('11h drive + 3h visit should overload');
"

echo "--- smoke: $pass passed, $fail failed ---"
exit $((fail>0))
