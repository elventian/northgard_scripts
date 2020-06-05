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
var shipArriveTime:Float = 0;
var curShipDelta:Float = 0;
var wyvernZone = 88;
var wyvern:Unit;

function saveState() {
	valkyrieZones = [];
	for (v in valkyries) {
		if (v.zone != null) { valkyrieZones.push(v.zone.id); }
	}
	for (s in specters) {
		if (specterZones.indexOf(s.zone.id) == -1) {
			specterZones.push(s.zone.id);
		}
	}
	wyvernZone = wyvern.zone.id;
	state.scriptProps = {
		savedInt 		: savedInt,
		prevDiscoveredZones: prevDiscoveredZones,
		towerZones: towerZones,
		prevTowerZones: prevTowerZones,
		scoutZones: scoutZones,
		scoutZonesTime: scoutZonesTime,
		prevUnitZones: prevUnitZones,
		valkyrieZones: valkyrieZones,
		specterZones: specterZones,
		shipArriveTime: shipArriveTime,
		curShipDelta: curShipDelta,
		wyvernZone: wyvernZone
	};
}


// --- Settings ---
var drakkarSpawnZone = 137;
var scoutDiscoverTimeout = 40; //time, after which zone will be hidden
var aggroArmySize = 4; //player army size, from which Valkyrie will attack
var valkyrieRetreatHp = 40;
var valkyrieAttackHp = 90;
var shipSpawnDelay = 480; //sec
var shipSpawnDelta = 60; //sec
// --- Local variables ---
var suppliesSent = true;
var regenHpPerTick = 2; //valkyrie regen rate in percents
var prevUnits:Array<Unit> = [];
var newbornSpecters:Array<Unit> = [];
var specterSpawnTime:Array<Float> = [];
var shipwrack = 128;
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

function createObjectives() {
	state.objectives.title = "Settle on island and find its secrets"; //FIXME: why not displayed?
	state.objectives.summary = "Settle on island and find its secrets";

	state.objectives.add("Watchtower", "Here we are, on this beautiful untouched island. Let's look around. Build a Defense Tower");
	state.objectives.add("Lighthouse", "Build a lighthouse to help other ships find their way here");
	state.objectives.add("Lost ship", "One of our ships went astray, send expedition to find where it moored");
	state.objectives.add("Specters", "What was that?! One of our people just died and turned into a ghost! Follow him");
	state.objectives.add("Guards", "Looks like they defend something. Island from strangers? They won't let us settle here, we have to end them.");
	state.objectives.add("Wyvern", "Valkyries guarded ancient evil beast - Undead Wyvern... and we let it free. Kill or be killed!");
	state.objectives.setVisible("Lighthouse", false);
	state.objectives.setVisible("Lost ship", false);
	state.objectives.setVisible("Specters", false);
	state.objectives.setVisible("Guards", false);
	state.objectives.setVisible("Wyvern", false);
}

function objectiveDone(name: String) {
	state.objectives.setStatus(name, OStatus.Done);
	state.objectives.setVisible(name, false);
}

function updateObjectives() {
	if (state.objectives.getStatus("Watchtower") == OStatus.Empty) {
		if (player.hasBuilding(Building.WatchTower, false)) {
			objectiveDone("Watchtower");
			state.objectives.setVisible("Lighthouse", true);
			state.objectives.setVisible("Lost ship", true);
		}
	}
	else {
		if (state.objectives.getStatus("Lighthouse") == OStatus.Empty) {
			if (player.hasBuilding(Building.Port, false, false, true)) {
				objectiveDone("Lighthouse");
			}
		}

		if (state.objectives.getStatus("Lost ship") == OStatus.Empty) {
			var shipZone = getZone(shipwrack);
			if (player.hasDiscovered(shipZone)) {
				objectiveDone("Lost ship");
				shipZone.addUnit(Unit.Sailor, 3);
				shipZone.addUnit(Unit.Death, 1);
				moveCamera(shipZone);
			}
		}
	}

	if (state.objectives.getStatus("Specters") == OStatus.Empty) {
		if (!state.objectives.isVisible("Specters") && specters.length > 0) {
			state.objectives.setVisible("Specters", true);
			moveCamera(specters[0].zone);
		}
		for (zoneId in thorZones) {
			var zone = getZone(zoneId);
			var done = false;
			if (player.hasDiscovered(zone)) {
				for (unit in zone.units) {
					if (unit.kind == Unit.SpecterWarrior) {
						moveCamera(zone);
						objectiveDone("Specters");
						state.objectives.setVisible("Guards", true);
						done = true;
						break;
					}
				}
			}
			if (done) { break; }
		}
	}

	if (state.objectives.getStatus("Guards") == OStatus.Empty && getActiveValkyrie() == null) {
		objectiveDone("Guards");
		state.objectives.setVisible("Wyvern", true);
	}

	if (state.objectives.isVisible("Wyvern")) {
		if (wyvern.zone == null) {
			player.triggerVictory(VictoryKind.VHelheim);
		}
		else if (player.units.length == 0) {
			customDefeat("All your units are dead");
		}
	}
	heartbeat();
}

function onFirstLaunch() {
	createObjectives();

	state.removeVictory(VictoryKind.VMilitary);
	state.removeVictory(VictoryKind.VFame);
	state.removeVictory(VictoryKind.VLore);
	state.removeVictory(VictoryKind.VMoney);
	addRule(Rule.VillagerStrike);
	player.addResource(Resource.Food, 100);
	//player.addResource(Resource.Money, 500);
	player.setTech([Tech.Drakkars]);
	//player.addResource(Resource.Wood, 60);
	spawnInitialUnits();
	curShipDelta = random(shipSpawnDelta) - shipSpawnDelta/2;
	valkyrieZones = thorZones.copy();
}

function onEachLaunch() {
	//load valkyries
	for (zone in valkyrieZones) {
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
	}

	wyvern = null;
	for (unit in getZone(wyvernZone).units) {
		if (unit.kind == Unit.WyvernUndead) {
			wyvern = unit;
		}
	}
}

//FIX: if regularUpdate runs for too long, the game will exit
//need to show to main thread, that I'm alive
function heartbeat() {
	wait(0.01);
}

function spawnInitialUnits() {
	player.zones[0].addUnit(Unit.Warrior, 2, player);
	player.zones[0].addUnit(Unit.AxeWielder, 1, player);
	player.zones[0].addUnit(Unit.Sheep, 2, player);
}

function generateDrakkarUnits(): Array<UnitKind> {
	var armySize = randomInt(5);
	var axeNum = randomInt(3);
	var civilNum = randomInt(2);

	var res:Array<UnitKind> = [];
	for (i in 0...axeNum) { res.push(Unit.AxeWielder); }
	for (i in 0...(armySize - axeNum)) { res.push(Unit.Warrior); }
	for (i in 0...civilNum) { res.push(Unit.Villager); }
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
			if (towerZones.indexOf(zone.id) == -1 &&
				prevDiscoveredZones.indexOf(zone.id) == -1 &&
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
				heartbeat();
				var nb:Array<Int> = getNeighbours(zone.id);
				for (neighbourId in nb) {
					if (towerZones.indexOf(neighbourId) == -1) {
						towerZones.push(neighbourId);
					}
					var neighZone = getZone(neighbourId);
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

	heartbeat();
}

function updateSpecters() {
	if (getActiveValkyrie() == null) {
		for (s in specters) {
			s.die(true);
		}
		specters = [];
		return;
	}

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
	heartbeat();
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

function valkyrieAttack(unit:Unit) {
	for (s in specters) {
		s.moveToZone(unit.zone, true, null, unit);
	}
	var valkyrie = getActiveValkyrie();
	valkyrie.moveToZone(unit.zone, true, null, unit);
}

function getUnitHealthPercents(unit: Unit) {
	return unit.life / unit.maxLife * 100;
}

function regenerate(units: Array<Unit>, zones: Array<Int>) {
	for (u in units) {
		if (u.zone == null) { continue; }
		if (zones.indexOf(u.zone.id) != -1) {
			u.hitLife -= (u.maxLife / 100 * regenHpPerTick);
			if (u.hitLife < 0) { u.hitLife = 0; }
		}
	}
}

function getUnitWithLessHealth(units: Array<Unit>) {
	var res = null;
	var hp:Float = 1000;
	for (unit in units) {
		if (unit.isMilitary && unit.owner == player && (res == null || hp > unit.life ) && unit.zone != null) {
			hp = unit.life;
			res = unit;
		}
	}
	return res;
}

function updateValkyries() {
	//remove dead specters from array
	specters = [for (s in specters ) if (s.zone != null) s];
	//regenerate
	regenerate(valkyries, thorZones);
	regenerate(specters, thorZones);
	//valkyrie AI
	var valkyrie = getActiveValkyrie();
	if (valkyrie != null) {
		var armySize = player.getMilitaryCount();
		if (armySize < aggroArmySize || getUnitHealthPercents(valkyrie) < valkyrieRetreatHp) { //move back to Thore
			var baseZone = getValkyrieThorZone(valkyrie);
			if (valkyrie.zone != baseZone) {
				for (s in specters) {
					s.moveToZone(baseZone, false);
				}
				valkyrie.moveToZone(baseZone, false);
			}
		}
		else if (getUnitHealthPercents(valkyrie) > valkyrieAttackHp) {
			var unit = getUnitWithLessHealth(valkyrie.zone.units);
			if (unit == null) {
				unit = getUnitWithLessHealth(player.units);
			}
			if (unit != null) {
				valkyrieAttack(unit);
			}
		}
	}

	heartbeat();

	updateSpecters();

	prevUnits = player.units.copy();
	prevUnitZones = [];
	for (i in 0...player.units.length) {
		if (player.units[i].zone != null) {
			prevUnitZones[i] = player.units[i].zone.id;
		}
	}
}

function updateShips() {
	if (player.hasBuilding(Building.Port, false, false, true)) {
		var lightZone = player.zones[0];
		if (shipArriveTime == 0) { //just built lighthouse
			shipArriveTime = state.time;
		}
		else if (state.time - shipArriveTime > shipSpawnDelay + curShipDelta) { //spawn drakkar
			curShipDelta = randomInt(shipSpawnDelta) - shipSpawnDelta/2;
			shipArriveTime = state.time;
			suppliesSent = false;
			//TODO check where's lighthouse
			drakkar(player, lightZone, getZone(drakkarSpawnZone), 0, 0, generateDrakkarUnits());
		}
		//FIX: I cannot send ships with drakkar via API
		if (!suppliesSent && state.time - shipArriveTime > 10) {
			suppliesSent = true;
			var shipsNum = randomInt(3) + 1;
			lightZone.addUnit(Unit.Sheep, shipsNum);
		}
	}
	heartbeat();
}

function updateWyvern() {
	if (wyvern.zone == null || getActiveValkyrie() != null) { return; } //activate only when valkyries are dead
	if (player.units.length > 0) {
		if (wyvern.zone.units.length <= 1) { //self
			var unit = getUnitWithLessHealth(player.units);
			wyvern.moveToZone(unit.zone, true, null, unit);
		}
	}
	heartbeat();
}

// Regular update is called every 0.5s
function regularUpdate(dt : Float) {
	updateFog();
	updateValkyries();
	updateWyvern();
	updateShips();
	updateObjectives();
}