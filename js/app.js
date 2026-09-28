/* RoadTrip AI — UI wiring. Runs in the browser. */
(function () {
  "use strict";
  const $ = (id) => document.getElementById(id);
  const LS_KEY = "roadtrip.trips.v1";
  let waypoints = [];

  function loadTrips() { try { return JSON.parse(localStorage.getItem(LS_KEY) || "[]"); } catch (e) { return []; } }
  function saveTrips(t) { localStorage.setItem(LS_KEY, JSON.stringify(t)); }
  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, (m) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[m]));
  }
  const money = (n) => "$" + (Math.round(n * 100) / 100).toFixed(2);

  function renderWaypoints() {
    const el = $("wpList");
    el.innerHTML = waypoints.map((w, i) =>
      "<div class='wp-row'><span><strong>" + (i + 1) + ".</strong> " + escapeHtml(w.name) +
      (w.notes ? " <span class='muted'>— " + escapeHtml(w.notes) + "</span>" : "") + "</span>" +
      "<button class='danger' data-wp='" + i + "'>Remove</button></div>"
    ).join("") || "<p class='muted'>No stops yet — add your first stop above.</p>";
    el.querySelectorAll("[data-wp]").forEach((b) => b.addEventListener("click", () => {
      waypoints.splice(parseInt(b.getAttribute("data-wp"), 10), 1);
      renderWaypoints();
    }));
  }

  function currentInputs() {
    return {
      name: $("tripName").value.trim() || "My road trip",
      origin: $("origin").value.trim(), destination: $("destination").value.trim(),
      days: $("days").value, distanceMi: $("distance").value,
      mpg: $("mpg").value, gasPrice: $("gasPrice").value,
      lodgingPerNight: $("lodging").value, nights: $("nights").value,
      foodPerDay: $("food").value, activitiesCost: $("activities").value
    };
  }

  function plan() {
    const v = currentInputs();
    const fuel = estimateFuel({ distanceMi: v.distanceMi, mpg: v.mpg, gasPrice: v.gasPrice });
    const days = Math.max(1, parseInt(v.days, 10) || 1);
    const itin = buildItinerary({ days, stops: waypoints });
    const budget = budgetSummary({
      fuelCost: fuel.cost, lodgingPerNight: v.lodgingPerNight, nights: v.nights,
      foodPerDay: v.food, days: days, activitiesCost: v.activitiesCost
    });

    let html = "<h2>🗺️ " + escapeHtml(v.name) + "</h2>";
    if (v.origin || v.destination) html += "<p class='muted'>" + escapeHtml(v.origin) + " → " + escapeHtml(v.destination) + "</p>";

    html += "<div class='stats'>";
    html += stat("⛽ Fuel", money(fuel.cost), fuel.gallons + " gal");
    html += stat("🕐 Drive time", fuel.distanceMi ? driveTimeHours(v.distanceMi, 55) + " h" : "—", "at ~55 mph avg");
    html += stat("💰 Total budget", money(budget.total), money(perDayCost(budget.total, days)) + " / day");
    html += "</div>";

    html += "<h3>Day-by-day itinerary</h3>";
    for (const d of itin) {
      html += "<div class='day'><h4>Day " + d.day + "</h4>";
      if (!d.stops.length) html += "<p class='muted'>Open road — no stops planned.</p>";
      else html += "<ul>" + d.stops.map((s) => "<li><strong>" + escapeHtml(s.name) + "</strong>" + (s.notes ? " — " + escapeHtml(s.notes) : "") + "</li>").join("") + "</ul>";
      html += "</div>";
    }

    html += "<h3>Budget breakdown</h3><table class='budget'><tbody>" +
      row("Fuel", budget.fuel) + row("Lodging (" + (parseInt(v.nights, 10) || 0) + " nights)", budget.lodging) +
      row("Food (" + days + " days)", budget.food) + row("Activities & extras", budget.activities) +
      "<tr class='total'><td>Total</td><td>" + money(budget.total) + "</td></tr></tbody></table>";

    html += "<h3>🚗 Car packing checklist</h3><ul class='pack'>";
    const packed = JSON.parse(localStorage.getItem("roadtrip.packed.v1") || "[]");
    html += CAR_ESSENTIALS.map((c, i) =>
      "<li><label><input type='checkbox' data-pack='" + i + "'" + (packed.includes(i) ? " checked" : "") + "> " + escapeHtml(c) + "</label></li>"
    ).join("") + "</ul><p class='muted'>Need a full suitcase list too? Try our companion app <strong>TravelPack AI</strong>.</p>";

    $("result").innerHTML = html;
    $("result").style.display = "block";
    $("result").querySelectorAll("[data-pack]").forEach((cb) => cb.addEventListener("change", () => {
      let p = JSON.parse(localStorage.getItem("roadtrip.packed.v1") || "[]");
      const i = parseInt(cb.getAttribute("data-pack"), 10);
      p = cb.checked ? [...new Set([...p, i])] : p.filter((x) => x !== i);
      localStorage.setItem("roadtrip.packed.v1", JSON.stringify(p));
    }));

    // persist trip
    const trips = loadTrips().filter((t) => t.name !== v.name);
    trips.push(Object.assign({}, v, { waypoints }));
    saveTrips(trips);
    renderSaved();
    window.scrollTo({ top: $("result").offsetTop - 20, behavior: "smooth" });
  }

  function stat(label, big, small) {
    return "<div class='stat'><div class='s-label'>" + label + "</div><div class='s-big'>" + big + "</div><div class='s-small'>" + small + "</div></div>";
  }
  function row(label, val) { return "<tr><td>" + escapeHtml(label) + "</td><td>" + money(val) + "</td></tr>"; }

  function renderSaved() {
    const trips = loadTrips();
    const el = $("savedList");
    el.innerHTML = trips.length ? trips.map((t) =>
      "<div class='trip-row'><button class='link' data-load='" + escapeHtml(t.name) + "'>" + escapeHtml(t.name) + "</button>" +
      "<span class='muted'>" + (parseInt(t.days, 10) || 1) + "d · " + (t.waypoints || []).length + " stops</span>" +
      "<button class='danger' data-del='" + escapeHtml(t.name) + "'>Delete</button></div>"
    ).join("") : "<p class='muted'>No saved trips yet.</p>";
    el.querySelectorAll("[data-load]").forEach((b) => b.addEventListener("click", () => {
      const t = loadTrips().find((x) => x.name === b.getAttribute("data-load"));
      if (!t) return;
      $("tripName").value = t.name; $("origin").value = t.origin || ""; $("destination").value = t.destination || "";
      $("days").value = t.days; $("distance").value = t.distanceMi; $("mpg").value = t.mpg;
      $("gasPrice").value = t.gasPrice; $("lodging").value = t.lodgingPerNight; $("nights").value = t.nights;
      $("food").value = t.foodPerDay; $("activities").value = t.activitiesCost;
      waypoints = t.waypoints || []; renderWaypoints(); plan();
    }));
    el.querySelectorAll("[data-del]").forEach((b) => b.addEventListener("click", () => {
      saveTrips(loadTrips().filter((x) => x.name !== b.getAttribute("data-del")));
      renderSaved();
    }));
  }

  document.addEventListener("DOMContentLoaded", () => {
    $("addWp").addEventListener("click", () => {
      const name = $("wpName").value.trim();
      if (!name) return;
      waypoints.push({ name, notes: $("wpNotes").value.trim() });
      $("wpName").value = ""; $("wpNotes").value = "";
      renderWaypoints();
    });
    $("planBtn").addEventListener("click", plan);
    renderWaypoints();
    renderSaved();
  });
})();
