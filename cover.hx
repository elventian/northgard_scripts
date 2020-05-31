// --- Saved variables ---
// You can add what you want to the save
savedInt 		= 0; // Here is the initialization for the first launch, after that the value will depend on what has been saved

function saveState() {
	state.scriptProps = {
		savedInt 		: savedInt,
	};
}


// --- Local variables ---
var prevDiscoveredZones:Array<Int> = [];
var towerZones:Array<Int> = [];
var prevTowerZones:Array<Int> = [];
var scoutZones:Array<Int> = [];
var scoutZonesTime:Array<Float> = [];
var zones = [122, 107, 112];
var neighbours:Array<Array<Int>> = [[107, 112, 127], [122, 112, 100], [107, 122, 127, 111, 91, 100, 121]];
function getNeighbours(zoneId: Int) : Array<Int> {
	for (i in 0...zones.length) {
		if (zones[i] == zoneId) {
			return neighbours[i].copy();
		}
	}
	return neighbours[0].copy();
}

// --- Script code ---
function init() {
	if (state.time == 0)
		onFirstLaunch();
	onEachLaunch();
}

function onFirstLaunch() {
	state.objectives.title = "Settle on island and find its secrets"; //TODO: why not displayed?
	state.objectives.summary = "Settle on island and find its secrets";

	state.objectives.add("Settle", "Colonize ::value:: zones with food sources");
	state.objectives.setGoalVal("Settle", 2);
	state.objectives.setCurrentVal("Settle", 0);

	state.objectives.add("Comrads", "Find lost ship of Delmutt");
}

function onEachLaunch() {

}

function playerHasUnitsInZone(zone: Zone) {
	for (unit in zone.units) {
		if (unit.owner == player) { return true; }
	}
	return false;
}

function updateFog() {
	//register zones, opened by Scouts (need hide them after time)
	if (prevDiscoveredZones.length > 0) {
		for (zone in player.discovered) {
			if (prevDiscoveredZones.indexOf(zone.id) == -1 &&
				towerZones.indexOf(zone.id) == -1 &&
				scoutZones.indexOf(zone.id) == -1) {
				scoutZones.push(zone.id);
				scoutZonesTime.push(state.time);
				trace(scoutZones);
			}
		}
	}
	trace(scoutZonesTime);

	//discover new zones, opened by watch towers
	towerZones = [];
	for (zone in player.zones) {
		for (building in zone.buildings) {
			if (building.kind == Building.WatchTower) {
				var nb:Array<Int> = getNeighbours(zone.id);
				for (neighbourId in nb) {
					var neighZone = getZone(neighbourId);
					if (towerZones.indexOf(neighbourId) == -1) {
						towerZones.push(neighbourId);
					}
					if (!player.hasDiscovered(neighZone)) {
						player.discoverZone(neighZone);
					}
				}
				break;
			}
		}
	}

	//hide zones that are no longer discovered by watch towers or scout timeout
	var needHide = false;
	for (zone in prevTowerZones) {
		if (towerZones.indexOf(zone) == -1 && player.zones.indexOf(getZone(zone)) == -1) {
			if (playerHasUnitsInZone(getZone(zone))) { //queue for cover
				var i = scoutZones.indexOf(zone);
				if (i == -1) {
					scoutZones.push(zone);
					scoutZonesTime.push(state.time);
				}
				else { scoutZonesTime[i] = state.time; }
			}
			else { needHide = true; }
		}
	}
	var tmpScoutZones:Array<Int> = [];
	var tmpScoutZonesTime:Array<Float> = [];
	for (i in 0...scoutZones.length) {
		if (scoutZonesTime[i] + 10 <= state.time &&
		towerZones.indexOf(scoutZones[i]) == -1 &&
		player.zones.indexOf(getZone(scoutZones[i])) == -1 &&
		!playerHasUnitsInZone(getZone(scoutZones[i]))) {
			needHide = true;
		}
		else {
			tmpScoutZones.push(scoutZones[i]);
			tmpScoutZonesTime.push(scoutZonesTime[i]);
		}
	}
	scoutZones = tmpScoutZones.copy();
	scoutZonesTime = tmpScoutZonesTime.copy();
	//FIXME: don't use coverAll(), if API will allow
	if (needHide) {
		player.coverAll();
		for (zoneId in towerZones) {
			player.discoverZone(getZone(zoneId));
		}
		for (zoneId in scoutZones) {
			player.discoverZone(getZone(zoneId));
		}
	}
	//FIX: always show colonized zones
	for (zone in player.zones) {
		if (!player.hasDiscovered(zone)) { player.discoverZone(zone); }
	}
	prevTowerZones = towerZones.copy();
	//FIX: hxbit.ArrayProxyData has no method a_copy
	prevDiscoveredZones = [];
	for (zone in player.discovered) {
		prevDiscoveredZones.push(zone.id);
	}
}

// Regular update is called every 0.5s
function regularUpdate(dt : Float) {
	updateFog();
}