var valkyries:Array<Unit> = [];
var specters:Array<Unit> = [];
var boss:Unit;
// --- Saved variables ---
// You can add what you want to the save
// Here is the initialization for the first launch, after that the value will depend on what has been saved
prevDiscoveredZones = [];
towerZones = [];
prevTowerZones = [];
scoutZones = [];
scoutZonesTime = [];
prevUnitZones = [];
valkyrieZones = [];
specterZones = [];
shipArriveTime = 0.0;
curShipDelta = 0.0;
bossZone = 88;
needProtectionTime = 0.0;
watchtowerDialog = false;
activeObjectives = [];
doneObjectives = [];
allObjectives = [];

function saveState() {
	valkyrieZones = [];
	for (v in valkyries) {
		if (v.zone != null) { valkyrieZones.push(v.zone.id); }
	}
	for (s in specters) {
		if (s.zone == null) { continue; }
		if (specterZones.indexOf(s.zone.id) == -1) {
			specterZones.push(s.zone.id);
		}
	}
	if (boss.zone != null) {
		bossZone = boss.zone.id;
	}
	state.scriptProps = {
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
		bossZone: bossZone,
		needProtectionTime: needProtectionTime,
		watchtowerDialog: watchtowerDialog,
		activeObjectives: activeObjectives,
		doneObjectives: doneObjectives,
		allObjectives: allObjectives
	};
}

// --- Settings ---
var drakkarSpawnZone = 137;
var scoutDiscoverTimeout = 180; //time, after which zone will be hidden
var aggroArmySize = 4; //player army size, from which Valkyrie will attack
var valkyrieRetreatHp = 40;
var valkyrieAttackHp = 90;
var shipSpawnDelay = 480; //sec
var shipSpawnDelta = 60; //sec
var regenHpPerTick = 2; //valkyrie regen rate in percents
var specterSpawnDelay = 10; //spawned specters will stay in zone for that time, then move to its mistress
var hideObjetivesTimeout = 10; //leave objective in list for n sec after it's Done
var showProtectionTimeout = 240; //time after which we show how to protect from specters
// --- Local variables ---
var suppliesSent = true;
var prevUnits:Array<Unit> = [];
var newbornSpecters:Array<Unit> = [];
var specterSpawnTime:Array<Float> = [];
var shipwrack = 128;
var thorZones = [102,82,77];
var carvedStones = [86,76,63,54];
var zones = [122, 107, 112, 127, 136, 121, 93, 64, 100, 86, 72, 57, 111, 91, 79, 69, 49, 128, 113, 101, 87, 76, 61, 134, 124, 110, 97, 82, 63,
54, 130, 117, 102, 88, 75, 59, 106, 94, 77, 85];
var hideObjetives:Array<String> = [];
var hideObjetivesTime:Array<Float> = [];
                                     //122              107         112                     127         136        121
var vNeighbours:Array<Array<Int>> = [[107,112,127], [122,112,100], [107,122,127,111,91,100,121], [122,112,136], [127,121], [112,111,113,128],
// 93                64     100                    86                 72            57             111                         91
[107,100,86,72,64], [57], [93,86,91,111,112,107], [93,100,91,79,72], [57,69,86,79], [64,72,69,49], [112,100,91,101,121,113], [100,86,79,87,101,111,112],
//79              69                      49           128           113         101                        87                     76
[86,72,69,76,91], [72,57,49,61,76,79,86], [57,69,61], [121,113,124], [121,110], [113,111,91,87,82,97,110], [91,79,76,82,97,101], [79,69,61,63,82,87],
//61               134           124                         110                97                          82             63
[49,69,76,63,54], [128,124,130], [128,113,110,117,130,134], [113,102,117,124], [101,87,82,88,102,110,113], [63,75,88,97], [61,54,59,75,82,76],
//54            130    117                   102                 88                  75                59             106             94
[61,59,49,63], [134], [130,124,110,102,106], [110,97,88,94,117], [82,75,77,94,102], [82,63,59,77,88], [54,63,75,77], [117,102,94,85], [102,88,77,85],
//77            85
[88,75,94,85], [94,77]];

									//122              107                   112              127       136        121
var neighbours:Array<Array<Int>> = [[107,112,127], [122,100], [122,127,111,91,100,121], [122,112,136], [127], [112,111,113,128],
// 93      64     100                    86                 72            57             111                         91
[100,86], [57], [93,86,91,111,112,107], [93,100,79,72], [57,69,86,79], [64,72,69,49], [112,100,91,101,121], [100,87,101,111,112],
//79              69                      49     128           113         101             87                     76
[86,72,69,76], [72,57,49,61,76,79,86], [57,69], [121,113,124], [121,110], [111,91,87,97], [91,76,101], [79,69,61,63,87],
//61            134        124                110                97            82             63
[69,76,63,54], [124,130], [128,110,117,134], [113,102,117,124], [101,82,102], [63,75,88,97], [61,54,75,82,76],
//54         130    117                   102                 88                  75        59     106     94
[61,59,63], [134], [124,110,102,106], [110,97,88,94,117], [82,77,94,102], [82,63,59,77], [54,75], [117], [102,88,77],
//77            85
[88,75,94,85], [77]];

function getVisNeighbours(zoneId: Int) : Array<Int> {
	for (i in 0...zones.length) {
		if (zones[i] == zoneId) {
			return vNeighbours[i].copy();
		}
	}
	return vNeighbours[0].copy();
}

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
	if (state.time == 0) {
		onFirstLaunch();
	}
	else {
		recoverObjectives(); //FIXME: remove when it will be fixed in game
	}
	onEachLaunch();
}

function hideAllObjectives() {
	for (obj in allObjectives) {
		state.objectives.setVisible(obj, false);
	}
}

function pushObjective(title: String, text: String) {
	state.objectives.add(title, text);
	allObjectives.push(title);
}

function createObjectives() {
	state.objectives.title = "Settle on island and find its secrets"; //FIXME: why not displayed?
	state.objectives.summary = "Settle on island and find its secrets";

	pushObjective("Watchtower", "Build a Defense Tower");
	pushObjective("Lighthouse", "Build a Lighthouse");
	pushObjective("LostShip", "Find our second ship somewhere in the south");
	pushObjective("Specters", "Find a place where headed the specter");
	pushObjective("Protection", "Scout island to find a way to stop raids");
	pushObjective("Stones", "Block the way of specters with Carved Stones");
	pushObjective("Guards", "Kill all valkyries");
	pushObjective("Boss", "Defeat Ice golem");

	hideAllObjectives();
	showObjective("Watchtower");
}

function recoverObjectives() {
	hideAllObjectives();

	for (obj in allObjectives) {
		state.objectives.setStatus(obj, OStatus.Empty);
	}

	for (obj in doneObjectives) {
		state.objectives.setStatus(obj, OStatus.Done);
	}

	for (obj in activeObjectives) {
		state.objectives.setVisible(obj, true);
	}
}

function moveCameraDiscovered(zone: Zone) {
	if (player.hasDiscovered(zone)) {
		moveCamera(zone);
	}
}

function objectiveDone(name: String) {
	state.objectives.setStatus(name, OStatus.Done);
	hideObjetives.push(name);
	hideObjetivesTime.push(state.time);
	activeObjectives.remove(name);
	doneObjectives.push(name);
}

function showObjective(name: String) {
	state.objectives.setVisible(name, true);
	activeObjectives.push(name);
}

function updateObjectives() {
	if (hideObjetives.length > 0 &&
	hideObjetivesTime[hideObjetives.length - 1] + hideObjetivesTimeout < state.time) {
		state.objectives.setVisible(hideObjetives[hideObjetives.length - 1], false);
		hideObjetives.pop();
		hideObjetivesTime.pop();
	}

	heartbeat();

	if (state.objectives.getStatus("Watchtower") == OStatus.Empty) {
		if (!watchtowerDialog) {
			watchtowerDialog = true;
			talk("We sailed to Sunspear Reefs to build new home, and finally we're here, on this beautiful untouched island! Let's look around. If we build a Defense Tower, we could see far into wild lands.");
		}
		if (player.hasBuilding(Building.WatchTower, false)) {
			objectiveDone("Watchtower");
			showObjective("Lighthouse");
			showObjective("LostShip");
			talk("When we almost reached the island, our second ship went astray. We should send expedition to find where she moored. And we need to build a Lighthouse, so other ships of our clan could navigate here.");
		}
	}

	heartbeat();

	if (state.objectives.getStatus("Lighthouse") == OStatus.Empty) {
		if (player.hasBuilding(Building.Port, false, false, true)) {
			objectiveDone("Lighthouse");
		}
	}

	heartbeat();

	if (state.objectives.getStatus("LostShip") == OStatus.Empty) {
		var shipZone = getZone(shipwrack);
		if (player.hasDiscovered(shipZone)) {
			objectiveDone("LostShip");
			shipZone.addUnit(Unit.Sailor, 2);
			var warrior = shipZone.addUnit(Unit.Warrior)[0];
			warrior.hitLife = warrior.maxLife * 0.85;
			shipZone.addUnit(Unit.Bear);
			moveCamera(shipZone);
		}
	}

	heartbeat();

	if (state.objectives.getStatus("Specters") == OStatus.Empty) {
		if (!state.objectives.isVisible("Specters") && newbornSpecters.length > 0) {
			showObjective("Specters");
			moveCameraDiscovered(newbornSpecters[0].zone);
			talk("What was that?! One of our people just died and turned into a ghost! We need to investigate this. Follow him!");
		}
		for (zoneId in thorZones) {
			heartbeat();
			var zone = getZone(zoneId);
			var done = false;
			if (player.hasDiscovered(zone)) {
				for (unit in zone.units) {
					if (unit.kind == Unit.SpecterWarrior) {
						moveCameraDiscovered(zone);
						objectiveDone("Specters");
						showObjective("Guards");
						talk("Looks like valkyries and specters defend something. Island from strangers? They won't let us settle, we have to end them.");
						done = true;
						for (zone in valkyrieZones) {
							player.discoverZone(getZone(zone));
						}
						break;
					}
				}
			}
			if (done) { break; }
		}
	}
	else if (state.objectives.getStatus("Protection") == OStatus.Empty) {
		if (specters.length >= 10 && !state.objectives.isVisible("Protection")) {
			showObjective("Protection");
			needProtectionTime = state.time;
			talk("We cannot gather big enough army to kill all specters... Need to find a way to stop their raids. Maybe the answer somewhere on the island?");
		}
		else if (state.objectives.isVisible("Protection") &&
		needProtectionTime + showProtectionTimeout < state.time) {
			objectiveDone("Protection");
			for (zone in carvedStones) {
				player.discoverZone(getZone(zone));
			}
			moveCamera(getZone(carvedStones[2]));
			showObjective("Stones");
			talk("Someone built those Carved Stones as a protection from specters. Maybe we should try it too.");
		}
		heartbeat();
	}

	if (state.objectives.getStatus("Stones") == OStatus.Empty &&
	state.objectives.isVisible("Stones") &&
	player.hasBuilding(Building.CarvedStone)) {
		objectiveDone("Stones");
	}

	heartbeat();

	if (state.objectives.getStatus("Guards") == OStatus.Empty && getActiveValkyrie() == null) {
		objectiveDone("Guards");
		showObjective("Boss");
		talk("Valkyries guarded ancient evil creature... and we let it free. Kill or be killed!");
	}

	heartbeat();

	if (state.objectives.isVisible("Boss")) {
		if (boss.zone == null) {
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

	player.addResource(Resource.Food, 160);
	player.setTech([Tech.Drakkars]);
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

	boss = null;
	for (unit in getZone(bossZone).units) {
		if (unit.kind == Unit.IceGolem) {
			boss = unit;
			break;
		}
	}

	addRule(Rule.VillagerStrike);
}

//FIX: if regularUpdate runs for too long, the game will exit
//need to show to main thread, that I'm alive
function heartbeat() {
	wait(0.001);
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
	heartbeat();
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

	heartbeat();

	//discover new zones, opened by watch towers
	towerZones = [];
	for (zone in player.zones) {
		for (building in zone.buildings) {
			if (building.kind == Building.WatchTower) {
				heartbeat();
				var nb:Array<Int> = getVisNeighbours(zone.id);
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

	heartbeat();

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

	heartbeat();

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
	heartbeat();
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
	heartbeat();
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
		if (t + specterSpawnDelay < state.time) {
			specters.push(newbornSpecters[n]);
			rmNewbornSpecters.push(newbornSpecters[n]);
			rmSpecterSpawnTime.push(specterSpawnTime[n]);
			n++;
		}
		else break;
	}

	heartbeat();

	for (specter in rmNewbornSpecters) { newbornSpecters.remove(specter); }
	for (stime in rmSpecterSpawnTime) { specterSpawnTime.remove(stime); }

	heartbeat();

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

function valkyrieAttack(unit:Unit, zone:Zone) {
	for (s in specters) {
		s.moveToZone(zone, true, null); //specters attack anyone in zone, valkyrie attacks only warband
	}
	var valkyrie = getActiveValkyrie();
	valkyrie.moveToZone(zone, true, null, unit);
	heartbeat();
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
	heartbeat();
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
	heartbeat();
	return res;
}

function findPath(fromZone:Zone, toZone:Zone, noCarvedStones:Bool): Zone {
	if (fromZone.id == toZone.id) { return fromZone; }
	var handledZones:Array<Int> = [fromZone.id];
	var searchQueue:Array<Int> = [fromZone.id];
	var parents:Array<Array<Int>> = [];
	while (searchQueue.length > 0) {
		var curZoneId = searchQueue.pop();
		var nZones = getNeighbours(curZoneId);
		for (n in nZones) {
			if (handledZones.indexOf(n) == -1) {
				handledZones.push(n);
				var nZone = getZone(n);
				var blocked = false;
				if (noCarvedStones) {
					for (b in nZone.buildings) {
						if (b.kind == Building.CarvedStone) {
							blocked = true;
							break;
						}
					}
				}
				if (!blocked) {
					searchQueue.insert(0, n);
					parents.push([n, curZoneId]);

					if (n == toZone.id) { // found path!
						heartbeat();
						var curParent = n;
						var i = 0;
						while (i < parents.length) {
							if (parents[i][0] == curParent) {
								if (parents[i][1] == fromZone.id) {
									heartbeat();
									return getZone(curParent);
								}
								curParent = parents[i][1];
								i = 0;
								continue;
							}
							i++;
						}
					}
				}
			}
			heartbeat();
		}
	}
	return null;
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
				valkyrie.moveToZone(baseZone, false);
			}
			heartbeat();
			for (s in specters) {
				s.moveToZone(baseZone, false);
			}
		}
		else if (getUnitHealthPercents(valkyrie) > valkyrieAttackHp) {
			var unit = getUnitWithLessHealth(valkyrie.zone.units);
			if (unit == null) {
				unit = getUnitWithLessHealth(player.units);
			}
			if (unit != null && unit.zone != null) {
				var path = findPath(valkyrie.zone, unit.zone, true);
				if (path != null) {
					valkyrieAttack(unit, path);
				}
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
			var drakkarZone = getZone(drakkarSpawnZone);
			drakkar(player, lightZone, drakkarZone, 0, 0, generateDrakkarUnits());
			moveCamera(drakkarZone);
		}
		//FIX: I cannot send ships with drakkar via API
		if (!suppliesSent && state.time - shipArriveTime > 10) {
			suppliesSent = true;
			var shipsNum = randomInt(2);
			lightZone.addUnit(Unit.Sheep, shipsNum);
		}
	}
	heartbeat();
}

function updateBoss() {
	if (boss.zone == null || getActiveValkyrie() != null) { return; } //activate only when valkyries are dead
	if (player.units.length > 0) {
		for (unit in player.units) {
			if (unit.kind != Unit.Sailor && boss.zone.units.indexOf(unit) != -1) {
				boss.moveToZone(boss.zone, true);
				heartbeat();
				return;
			}
		}
		var unit = player.units[0];
		for (nextUnit in player.units) {
			if (nextUnit.kind != Unit.Sailor) {
				unit = nextUnit;
				break;
			}
		}
		if (unit.zone != null) {
			var nextZone = findPath(boss.zone, unit.zone, false);
			boss.moveToZone(nextZone, true);
		}
	}
	heartbeat();
}

// Regular update is called every 0.5s
function regularUpdate(dt : Float) {
	updateFog();
	updateValkyries();
	updateBoss();
	updateShips();
	updateObjectives();
}