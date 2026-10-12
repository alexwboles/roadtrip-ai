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

flow "round trip doubles fuel for the drive home" "
  const L=require('./js/logic.js');
  const f=L.estimateFuel({distanceMi:600,mpg:30,gasPrice:3.5,roundTrip:true});
  if(f.distanceMi!==1200||f.gallons!==40||f.cost!==140) throw new Error(JSON.stringify(f));"

flow "reorder keeps stop notes attached to the moved stop" "
  const L=require('./js/logic.js');
  const r=L.reorderStop([{name:'A'},{name:'GC',notes:'sunrise'},{name:'C'}],1,0);
  if(r[0].name!=='GC'||r[0].notes!=='sunrise') throw new Error('notes lost on move');
  if(r[2].name!=='C') throw new Error('wrong order');"

flow "full plan math: daily drive, fill-ups, summary" "
  const L=require('./js/logic.js');
  const fuel=L.estimateFuel({distanceMi:1100,mpg:25,gasPrice:4});
  const daily=L.dailyDriveHours(fuel.distanceMi,4);
  if(daily!==5) throw new Error('daily drive: '+daily);
  if(L.fillUps(fuel.gallons,12)!==4) throw new Error('fillups: '+L.fillUps(fuel.gallons,12));
  const b=L.budgetSummary({fuelCost:fuel.cost,lodgingPerNight:120,nights:3,foodPerDay:60,days:4,activitiesCost:100});
  const t=L.tripSummaryText({name:'West',origin:'Denver',destination:'Vegas',distanceMi:fuel.distanceMi,driveHours:L.driveTimeHours(fuel.distanceMi,55),dailyDriveHours:daily,gallons:fuel.gallons,fuelCost:fuel.cost,fillUps:L.fillUps(fuel.gallons,12),lodging:b.lodging,food:b.food,activities:b.activities,total:b.total,perDay:L.perDayCost(b.total,4),days:4,itinerary:L.buildItinerary({days:4,stops:[{name:'GC'}]})});
  if(t.indexOf('Denver → Vegas')===-1) throw new Error('route missing');
  if(t.indexOf('Day 1: GC')===-1) throw new Error('itinerary missing');"

flow "drive-day recommendation, dates, and day load" "
  const L=require('./js/logic.js');
  const dp=L.planDriveDays(1000,2,55,8);
  if(!dp.over||dp.daysNeeded!==3) throw new Error('should recommend 3 days');
  const dp2=L.planDriveDays(1000,dp.daysNeeded,55,8);
  if(dp2.over||dp2.dailyDrive!==6.1) throw new Error('fixed plan: '+JSON.stringify(dp2));
  const itin=L.itineraryWithDates(L.buildItinerary({days:3,stops:[{name:'GC',hoursAt:4},{name:'Canyon'}]}),'2026-10-12');
  if(itin[0].date!=='Mon 10/12') throw new Error('date: '+itin[0].date);
  const loads=L.dayLoadReport(itin,dp2.dailyDrive,12);
  if(loads[0].totalHrs!==10.1||loads[0].overloaded) throw new Error('day1 load: '+JSON.stringify(loads[0]));
  const heavy=L.dayLoadReport([{day:1,stops:[{name:'Museum',hoursAt:7}]}],6,12);
  if(!heavy[0].overloaded) throw new Error('13h day should be overpacked');
  const t=L.tripSummaryText({name:'West',days:3,itinerary:itin});
  if(t.indexOf('Day 1 (Mon 10/12):')===-1) throw new Error('dated summary: '+t);"

echo "--- e2e: $pass passed, $fail failed ---"
exit $((fail>0))
