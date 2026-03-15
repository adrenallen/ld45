extends Node2D

const MAX_FUEL_SCALE = 3.96
const SHIP_ENTER_DISTANCE = 150

# Wormhole spawn chance: ~30% base, increases with toxicity/radius
const WORMHOLE_BASE_CHANCE = 0.30

var minimumLaunchFuel = 30

var fuelScene = load("res://explore/Fuel.tscn")
var repairScene = load("res://explore/Repair.tscn")
var airPocketScene = load("res://explore/AirPocket.tscn")
var lootPickupScene = load("res://explore/LootPickup.tscn")
var wormholeScene = load("res://explore/Wormhole.tscn")
var deathMarkerScene = load("res://multiplayer/DeathMarker.tscn")

var tileSource = 0
var openAtlasCoords = Vector2i(0, 0)
var closedAtlasCoords = Vector2i(1, 0)

var mouseOnShip = false
var playerStartPos = Vector2(0, 0)

func _ready():
	setTileSource()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	placeWorld()
	Game.oxygen = Game.maxOxygen
	Game.planetsLandedOn += 1
	Game.playerInAirPocket = false

	# Degrade landing system on crash landing
	var gravity_factor = clamp(Game.currentPlanet.gravity / 40.0, 1, 3)
	Inventory.degrade_ship_equipment(Items.ShipSlot.LANDING_SYSTEM, gravity_factor)

	if MP.weeklyMode:
		MP.death_markers_loaded.connect(_on_death_markers_loaded)
		MP.fetchDeathMarkers(2)

func _physics_process(delta):
	if $CharacterBody2D.global_position.distance_to($"World/ship-top".global_position) < SHIP_ENTER_DISTANCE and mouseOnShip:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		$"World/ship-top".frame =1
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		$"World/ship-top".frame =0

func _process(delta):
	$UI.global_position = $CharacterBody2D/Camera2D.get_screen_center_position()
	$UI.global_position.x -= get_viewport_rect().size.x/2
	$UI.global_position.y -= get_viewport_rect().size.y/2

	$"UI/fuel-icon/fuel-body".scale.x = Game.fuel / float(Game.maxFuel) * MAX_FUEL_SCALE
	$"UI/o2/o2-body".scale.x = Game.oxygen / float(Game.maxOxygen) * MAX_FUEL_SCALE

	if $"UI/fuel-icon/fuel-body".scale.x > MAX_FUEL_SCALE:
		$"UI/fuel-icon/fuel-body".scale.x = MAX_FUEL_SCALE
	if $"UI/o2/o2-body".scale.x > MAX_FUEL_SCALE:
		$"UI/o2/o2-body".scale.x = MAX_FUEL_SCALE

	if Game.playerInAirPocket:
		if Game.oxygen < Game.maxOxygen:
			Game.oxygen += delta * Game.AIR_POCKET_OXYGEN_RATE
	else:
		var drain = delta * Game.currentPlanet.atmosphereToxicity * Game.oxygenEfficiency
		Game.oxygen -= drain

		# Degrade helmet and suit based on toxicity
		var toxicity = Game.currentPlanet.atmosphereToxicity
		Inventory.degrade_player_equipment(Items.EquipSlot.HELMET, delta * toxicity * Inventory.HELMET_WEAR_RATE)
		Inventory.degrade_player_equipment(Items.EquipSlot.SUIT, delta * toxicity * Inventory.SUIT_WEAR_RATE)

	if MP.weeklyMode:
		MP.updatePosition(2, $CharacterBody2D.global_position)

	if Game.oxygen <= 0:
		Game.oxygen = 0
		$CharacterBody2D.die()

func setTileSource():
	tileSource = 0
	if Game.currentPlanet.biome == Game.PlanetBiome.Forest:
		tileSource = 1
	elif Game.currentPlanet.biome == Game.PlanetBiome.Gas:
		tileSource = 2
	elif Game.currentPlanet.biome == Game.PlanetBiome.Water:
		tileSource = 3
	elif Game.currentPlanet.biome == Game.PlanetBiome.Fungal:
		tileSource = 4
	elif Game.currentPlanet.biome == Game.PlanetBiome.Lava:
		tileSource = 5

func nextPhase():
	Game.setPhase(3)

func _on_Transition_TransitionIn():
	$CharacterBody2D/Camera2D.make_current()

func placeWorld():
	var map = generateMap()

	var numberOfFuel = Game.currentPlanet.atmosphereToxicity * Game.currentPlanet.radius / 2.25
	var numberOfRepair = randi()%5
	var numberOfAirPockets = randi()%(3 + int(Game.currentPlanet.atmosphereToxicity))

	if Game.shipHealth > 3:
		numberOfRepair -= 1
	if Game.currentPlanet.atmosphereToxicity < (Game.MAX_ATMO_TOXIC/2):
		numberOfRepair -= 1

	var openSpots = []

	var playerStart = Vector2(0,0)
	for y in range(map.size()):
		for x in range(map[y].size()):
			if map[y][x] == 0:
				$TileMap.set_cell(0, Vector2i(x, y), tileSource, openAtlasCoords)
				openSpots.append(Vector2(x,y))
				playerStart.x = x
				playerStart.y = y
			else:
				$TileMap.set_cell(0, Vector2i(x, y), tileSource, closedAtlasCoords)

	playerStartPos = playerStart

	for i in range(numberOfFuel):
		_spawn_at_random(fuelScene, openSpots)

	for i in range(numberOfRepair):
		_spawn_at_random(repairScene, openSpots)

	for i in range(numberOfAirPockets):
		_spawn_at_random(airPocketScene, openSpots)

	# Spawn loot pickups
	_spawn_loot(openSpots)

	# Spawn wormhole (chance-based)
	_try_spawn_wormhole(openSpots)

	# position player start
	$CharacterBody2D.global_position = $TileMap.map_to_local(Vector2i(playerStart.x, playerStart.y))
	$CharacterBody2D.global_position.x += 32
	$CharacterBody2D.global_position.y += 32

	# make sure we dont open an out of world path
	for x in range(playerStart.x-9, playerStart.x+5):
		for y in range(playerStart.y-7, playerStart.y+7):
			if $TileMap.get_cell_source_id(0, Vector2i(x,y)) < 0:
				$TileMap.set_cell(0, Vector2i(x,y), tileSource, closedAtlasCoords)

	# make space for crash zone
	for x in range(playerStart.x-6, playerStart.x+2):
		for y in range(playerStart.y-4, playerStart.y+4):
			$TileMap.set_cell(0, Vector2i(x,y), tileSource, openAtlasCoords)

	$"World/ship-top".global_position = $CharacterBody2D.global_position
	$"World/ship-top".global_position.x -= 128

func _spawn_at_random(scene: PackedScene, openSpots: Array):
	if openSpots.size() == 0:
		return
	var randomLoc = randi() % openSpots.size()
	var randomSpot = openSpots[randomLoc]
	var loc = $TileMap.map_to_local(Vector2i(randomSpot.x, randomSpot.y))
	var instance = scene.instantiate()
	instance.position = loc
	instance.position.x += 32
	instance.position.y += 32
	$World.add_child(instance)
	openSpots.erase(randomSpot)

func _spawn_loot(openSpots: Array):
	var biome = Game.currentPlanet.biome
	var dist = Game.getMilesTraveled()
	var available_items = Items.get_items_for_biome(biome, dist)

	if available_items.size() == 0:
		return

	# Number of loot drops scales with radius and distance
	var base_loot = int(Game.currentPlanet.radius / 8.0)
	var distance_bonus = int(dist / 20000.0)
	var num_loot = max(2, base_loot + distance_bonus)
	num_loot = int(num_loot * Game.gatheringBonus)

	for i in range(num_loot):
		if openSpots.size() == 0:
			break

		# Weighted random selection - rarer items less likely
		var item = _pick_weighted_item(available_items)

		var randomLoc = randi() % openSpots.size()
		var randomSpot = openSpots[randomLoc]
		var loc = $TileMap.map_to_local(Vector2i(randomSpot.x, randomSpot.y))

		var loot = lootPickupScene.instantiate()
		loot.position = loc
		loot.position.x += 32
		loot.position.y += 32
		loot.init(item.id, 1)
		$World.add_child(loot)

		openSpots.erase(randomSpot)

func _pick_weighted_item(available: Array) -> Dictionary:
	# Weight by inverse rarity: common=10, uncommon=5, rare=2, epic=1, legendary=0.5
	var weights = {
		Items.Rarity.COMMON: 10.0,
		Items.Rarity.UNCOMMON: 5.0,
		Items.Rarity.RARE: 2.0,
		Items.Rarity.EPIC: 1.0,
		Items.Rarity.LEGENDARY: 0.5,
	}
	var total = 0.0
	for item in available:
		total += weights.get(item.get("rarity", Items.Rarity.COMMON), 1.0)

	var roll = randf() * total
	var cumulative = 0.0
	for item in available:
		cumulative += weights.get(item.get("rarity", Items.Rarity.COMMON), 1.0)
		if roll <= cumulative:
			return item

	return available[0]

func _try_spawn_wormhole(openSpots: Array):
	if openSpots.size() < 3:
		return

	# Chance increases with toxicity and radius
	var chance = WORMHOLE_BASE_CHANCE
	chance += Game.currentPlanet.atmosphereToxicity * 0.03
	chance += Game.currentPlanet.radius / 200.0

	if randf() > chance:
		return  # No wormhole this time

	# Place far from player start (find the farthest open spot)
	var best_spot = openSpots[0]
	var best_dist = 0.0
	for spot in openSpots:
		var d = spot.distance_to(playerStartPos)
		if d > best_dist:
			best_dist = d
			best_spot = spot

	var loc = $TileMap.map_to_local(Vector2i(best_spot.x, best_spot.y))
	var wormhole = wormholeScene.instantiate()
	wormhole.position = loc
	wormhole.position.x += 32
	wormhole.position.y += 32
	$World.add_child(wormhole)
	openSpots.erase(best_spot)

func generateMapOpen(dimensions):
	var array = []
	for i in range(0, dimensions):
		array.append([])
		for j in range(0, dimensions):
			array[i].append(1)
	return array

func generateMap():
	var dimensions = int(floor(Game.currentPlanet.radius*4))
	var maxTunnels = int(floor(randf_range(dimensions*.75, dimensions*4)))
	var maxLength = int(floor(randf_range(2,20)))
	var map = generateMapOpen(dimensions)
	var currentRow = randi()%dimensions
	var currentCol = randi()%dimensions

	var directions = [Vector2(-1,0), Vector2(1,0), Vector2(0,-1), Vector2(0,1)]
	var lastDirection = Vector2(0, 0)
	var randomDirection

	while maxTunnels > 0:
		randomDirection = directions[randi()%directions.size()]
		while (randomDirection.x == -lastDirection.x and randomDirection.y == -lastDirection.y) or (randomDirection.x == lastDirection.x and randomDirection.y == lastDirection.y):
			randomDirection = directions[randi()%directions.size()]

		var randomLength = randi()%maxLength+1
		var tunnelLength = 0

		while tunnelLength < randomLength:
			if (
				((currentRow == 1) and (randomDirection.x == -1)) or
				((currentCol == 1) and (randomDirection.y == -1)) or
				((currentRow >= dimensions - 2) and (randomDirection.x == 1)) or
				((currentCol >= dimensions - 2) and (randomDirection.y == 1))
			):
				break
			else:
				map[currentRow][currentCol] = 0
				currentRow += randomDirection.x
				currentCol += randomDirection.y
				tunnelLength += 1

		if tunnelLength > 0:
			lastDirection = randomDirection
			maxTunnels -= 1

	return map

func _on_Area2D_input_event(viewport, event, shape_idx):
	if $CharacterBody2D.dying:
		return
	if $CharacterBody2D.global_position.distance_to($"World/ship-top".global_position) < SHIP_ENTER_DISTANCE:
		if event is InputEventMouseButton:
			if Game.fuel >= minimumLaunchFuel:
				nextPhase()
			if Game.cheaterMode:
				nextPhase()

func _on_Area2D_mouse_entered():
	mouseOnShip = true

func _on_Area2D_mouse_exited():
	mouseOnShip = false

func _on_death_markers_loaded(phase):
	if phase != 2:
		return
	for marker in MP.deathMarkers[2]:
		var dm = deathMarkerScene.instantiate()
		dm.global_position = Vector2(marker.positionX, marker.positionY)
		dm.init(marker)
		$World.add_child(dm)
