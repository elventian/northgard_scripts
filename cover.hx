// --- Saved variables ---
// You can add what you want to the save
savedInt 		= 0; // Here is the initialization for the first launch, after that the value will depend on what has been saved
var prevDiscoveredZones:Array<Int> = [];
var towerZones:Array<Int> = [];
var prevTowerZones:Array<Int> = [];
var scoutZones:Array<Int> = [];
var scoutZonesTime:Array<Float> = [];
var prevUnitZones:Array<Int> = [];
var valkyrieZones:Array<Int> = [];
var specterZones:Array<Int> = [];
var valkyries:Array<Unit> = [];
var specters:Array<Unit> = [];

function saveState() {
	valkyrieZones = [];
	for (v in valkyries) {
		valkyrieZones.push(v.zone.id);
	}
	for (s in specters) {
		if (specterZones.indexOf(s.zone.id) == -1) {
			specterZones.push(s.zone.id);
		}
	}
	state.scriptProps = {
		savedInt 		: savedInt,
		prevDiscoveredZones: prevDiscoveredZones,
		towerZones: towerZones,
		prevTowerZones: prevTowerZones,
		scoutZones: scoutZones,
		scoutZonesTime: scoutZonesTime,
		prevUnitZones: prevUnitZones,
		valkyrieZones: valkyrieZones,
		specterZones: specterZones
	};
}


// --- Local variables ---
var drakkarSent = false;
var drakkarSpawnZone = 137;
var scoutDiscoverTimeout = 40; //time, after which zone will be hidden
var prevUnits:Array<Unit> = [];
var newbornSpecters:Array<Unit> = [];
var specterSpawnTime:Array<Float> = [];
var thorZones = [102,82,77];
var zones = [122, 107, 112, 127, 136, 121, 93, 64, 100, 86, 72, 57, 111, 91, 79, 69, 49, 128, 113, 101, 87, 76, 61, 134, 124, 110, 97, 82, 63,
54, 130, 117, 102, 88, 75, 59, 106, 94, 77, 85];
                                     //122              107                   112                     127         136        121
var neighbours:Array<Array<Int>> = [[107,112,127], [122,112,100], [107,122,127,111,91,100,121], [122,112,136], [127,121], [112,111,113,128],
// 93                64     100                    86              72            57             111                         91
[107,100,86,72,64], [57], [93,86,91,111,112,107], [93,100,91,79], [57,69,86,79], [64,72,69,49], [112,100,91,101,121,113], [100,86,79,87,101,111,112],
//79              69                      49           128           113         101                        87                     76
[86,72,69,76,91], [72,57,49,61,76,79,86], [57,69,61], [121,113,124], [121,110], [113,111,91,87,82,97,110], [91,79,76,82,97,101], [79,69,61,63,82,87],
//61               134           124                         110                97                          82             63
[49,69,76,63,54], [128,124,130], [128,113,110,117,130,134], [113,102,117,124], [101,87,82,88,102,110,113], [63,75,88,97], [61,54,59,75,82,76],
//54            130    117                   102                 88                  75                59             106             94
[61,59,49,63], [134], [130,124,110,102,106], [110,97,88,94,117], [82,75,77,94,102], [82,63,59,77,88], [54,63,75,77], [117,102,94,85], [102,88,77,85],
//77            85
[88,75,94,85], [94,77]];

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

	state.objectives.add("Lighthouse", "Build a lighthouse to help other ships find their way here");
	state.objectives.add("Lost ship", "One of your ships went astray, send expedition to find where it moored");

	addRule(Rule.VillagerStrike);
	player.addResource(Resource.Food, 100);

	spawnInitialUnits();

	//valkyrieZones = thorZones.copy();
}

function onEachLaunch() {
	//load valkyries
	/*for (zone in valkyrieZones) {
		for (unit in getZone(zone).units) {
			if (unit.kind == Unit.Valkyrie) {
				valkyries.push(unit);
			}
		}
	}
	for (zone in specterZones) {
		for (unit in getZone(zone).units) {
			if (unit.kind == Unit.SpecterWarrior) {
				specters.push(unit);
			}
		}
	}*/

}

function spawnInitialUnits() {
	player.zones[0].addUnit(Unit.Warrior, 2, player);
	player.zones[0].addUnit(Unit.AxeWielder, 1, player);
	player.zones[0].addUnit(Unit.Sheep, 2, player);
}

function generateDrakkarUnits(): Array<UnitKind> {
	var armySize = randomInt(6);
	var axeNum = randomInt(3);
	var civilNum = randomInt(3);
	var sheepNum = randomInt(2) + 1;

	var res:Array<UnitKind> = [];
	for (i in 0...axeNum) { res.push(Unit.AxeWielder); }
	for (i in 0...(armySize - axeNum)) { res.push(Unit.Warrior); }
	for (i in 0...civilNum) { res.push(Unit.Villager); }
	for (i in 0...sheepNum) { res.push(Unit.Wolf); }
	return res;
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
			}
		}
	}

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
		if (scoutZonesTime[i] + scoutDiscoverTimeout <= state.time &&
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

function updateSpecters() {
	if (getActiveValkyrie() == null) { return; }

	var rmNewbornSpecters:Array<Unit> = [];
	var rmSpecterSpawnTime:Array<Float> = [];
	var n = 0;
	for (t in specterSpawnTime) {
		if (t + 3 < state.time) { //spawned specters will stay in zone for 3s, then move to its mistress
			specters.push(newbornSpecters[n]);
			rmNewbornSpecters.push(newbornSpecters[n]);
			rmSpecterSpawnTime.push(specterSpawnTime[n]);
			n++;
		}
		else break;
	}
	for (specter in rmNewbornSpecters) { newbornSpecters.remove(specter); }
	for (stime in rmSpecterSpawnTime) { specterSpawnTime.remove(stime); }
	if (prevUnits.length > player.units.length) {
		for (i in 0...prevUnits.length) {
			if (prevUnits[i].zone == null) { //found dead unit, spawn specter
				var specter = getZone(prevUnitZones[i]).addUnit(Unit.SpecterWarrior)[0];
				specter.x = prevUnits[i].x;
				specter.y = prevUnits[i].y;
				newbornSpecters.push(specter);
				specterSpawnTime.push(state.time);
			}
		}
	}
}

function getActiveValkyrie() {
	for (v in valkyries) {
		if (v.zone != null) { return v; }
	}
	return null;
}

function getValkyrieThorZone(valkyrie:Unit) {
	var i = valkyries.indexOf(valkyrie);
	if (i == -1) { i = 0; }
	return getZone(thorZones[i]);
}

function updateValkyries() {
	//remove dead specters from array
	specters = specters.filter(function (unit) {return unit.zone != null; } );
	//valkyrie AI
	var valkyrie = getActiveValkyrie();
	if (valkyrie == null) {
		var waitSpecters = false;
		for (s in specters) {
			if (s.zone != valkyrie.zone) {
				s.moveToZone(valkyrie.zone, false);
				waitSpecters = true;
			}
		}
		if (waitSpecters) { return; }
		var armySize = player.getMilitaryCount();
		if (armySize <= 3) {
			valkyrie.moveToZone(getValkyrieThorZone(valkyrie), false);
		}
	}
}

// Regular update is called every 0.5s
function regularUpdate(dt : Float) {
	updateFog();
	updateValkyries();
	updateSpecters();

	var sheepsNum = 0;
	for (unit in player.zones[0].units) {
		if (unit.kind == Unit.Sheep) { sheepsNum++; }
	}

	if (state.time > 5 && !drakkarSent) {
		drakkarSent = true;
		//drakkar(player, player.zones[0], getZone(drakkarSpawnZone), 0, 0, generateDrakkarUnits());
	}
	prevUnits = player.units.copy();
	prevUnitZones = [];
	for (i in 0...player.units.length) {
		prevUnitZones[i] = player.units[i].zone.id;
	}
}