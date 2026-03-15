extends Node

enum PlanetBiome {
	Forest,
	Mountain,
	Fungal,
	Gas,
	Water,
	Lava
}

enum DeathBy {
	Sun,
	Planet,
	AlienShip,
	Suffocation
}

const MAX_ATMO_TOXIC = 5
const AIR_POCKET_OXYGEN_RATE = 5
const MAX_SHIP_HEALTH = 5
const BASE_URL = "https://ld45.garrettallen.dev/lb"
#const BASE_URL = "http://18.224.157.46:5000"

var fuel = 0
var oxygen = 100
var maxOxygen = 100
var maxFuel = 100
var shipHealth = MAX_SHIP_HEALTH
var maxShipHealth = MAX_SHIP_HEALTH
var tutorialsCompleted = []
var cheaterMode = false

var currentPlanet = {
	gravity = 200,
	radius = 32,
	biome = PlanetBiome.Mountain,
	atmosphereToxicity = 5
}

var debug = false
var planetsLandedOn = 0
var dead = false
var deathBy = {cause = null}
var quickTransitions = false

var distance = 0
var currentDistance = 0 #distance in current scene

var playerInAirPocket = false

# Run / meta-game state
var run_active = false
var extracted = false

# Persistent stats (saved)
var runs_completed: int = 0
var runs_died: int = 0
var items_crafted: int = 0
var successful_extractions: int = 0

# Equipment-derived stats (calculated at run start)
var oxygenEfficiency: float = 1.0
var speedModifier: float = 1.0
var damageResistance: int = 0
var fuelEfficiency: float = 1.0
var landingSpeedReduction: float = 0.0
var gatheringBonus: float = 1.0
var weaponDamage: int = 0
var fireRate: float = 0.0

func refresh():
	if MP.weeklyMode:
		seed(MP.weeklySeed)
	else:
		randomize()

	dead = false
	deathBy = {cause = null}
	planetsLandedOn = 0
	playerInAirPocket = false
	distance = 0
	currentDistance = 0
	extracted = false

	# Calculate stats from equipped gear
	_calculate_equipment_stats()

	setFirstPlanet()

func _calculate_equipment_stats():
	# Player equipment stats
	maxOxygen = Inventory.get_player_stat("oxygen_capacity", 100)
	oxygenEfficiency = Inventory.get_player_stat("oxygen_efficiency", 1.0)
	damageResistance = int(Inventory.get_player_stat("damage_resistance", 0))
	gatheringBonus = Inventory.get_player_stat("gathering_bonus", 1.0)

	# Combine suit + boots speed modifier
	var suit_def = Inventory.get_equipped_item_def(Items.EquipSlot.SUIT)
	var boots_def = Inventory.get_equipped_item_def(Items.EquipSlot.BOOTS)
	var suit_speed = suit_def.get("stats", {}).get("speed_modifier", 1.0)
	var boots_speed = boots_def.get("stats", {}).get("speed_modifier", 1.0)
	speedModifier = suit_speed * boots_speed

	# Ship equipment stats
	maxShipHealth = int(Inventory.get_ship_stat("hull_hp", MAX_SHIP_HEALTH))
	shipHealth = maxShipHealth
	fuelEfficiency = Inventory.get_ship_stat("fuel_efficiency", 1.0)
	maxFuel = int(Inventory.get_ship_stat("fuel_capacity", 100))
	landingSpeedReduction = Inventory.get_ship_stat("landing_speed_reduction", 0.0)
	weaponDamage = int(Inventory.get_ship_stat("weapon_damage", 0))
	fireRate = Inventory.get_ship_stat("fire_rate", 0.0)

	fuel = 20
	oxygen = maxOxygen

func setFirstPlanet():
	currentPlanet = generatePlanet()

	# First planet should be easy
	currentPlanet.atmosphereToxicity = 1.0
	currentPlanet.radius = 16.0
	currentPlanet.biome = PlanetBiome.Mountain

# Called when the node enters the scene tree for the first time.
func _ready():
	refresh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("debugger"):
		debug = !debug

func generatePlanet():
	return {
		radius = randf_range(16,64),
		gravity = randf_range(20, 80),
		biome = PlanetBiome.values()[randi()%PlanetBiome.values().size()],
		atmosphereToxicity = randf_range(1,MAX_ATMO_TOXIC)
	}

func setPlanet(planetNode):
	self.currentPlanet = {
		radius = planetNode.planetRadius,
		gravity = planetNode.gravity,
		biome = planetNode.biome,
		atmosphereToxicity = planetNode.atmosphereToxicity
	}
	print(currentPlanet)

func addFuel(amt):
	if fuel < maxFuel:
		fuel += amt
	if fuel > maxFuel:
		fuel = maxFuel

func repairShip():
	if shipHealth != maxShipHealth:
		shipHealth += 1

func getCurrentBiomeTint():
	var bgColor = Color(165, 238, 255)
	if currentPlanet.biome == PlanetBiome.Forest:
		bgColor = Color(42,255,245)
	elif currentPlanet.biome == PlanetBiome.Fungal:
		bgColor = Color(255,118,118)
	elif currentPlanet.biome == PlanetBiome.Water:
		bgColor = Color(131,197,255)
	elif currentPlanet.biome == PlanetBiome.Lava:
		bgColor = Color(231,141,97)
	elif currentPlanet.biome == PlanetBiome.Mountain:
		bgColor = Color(193,193,193)
	elif currentPlanet.biome == PlanetBiome.Gas:
		bgColor = Color(231,255,177)

	#Fix for dumb
	bgColor /= 255.0
	bgColor *= .75
	bgColor.a = 1

	return bgColor

func die(deathInfo = null):
	if deathInfo:
		deathBy = deathInfo
	else:
		deathBy.biome = Game.currentPlanet.biome
		deathBy.radius = Game.currentPlanet.radius
		deathBy.atmosphereToxicity = Game.currentPlanet.atmosphereToxicity
		deathBy.cause = Game.DeathBy.Planet
		deathBy.gravity = Game.currentPlanet.gravity

	dead = true
	run_active = false
	runs_died += 1

	# Handle inventory loss and durability
	Inventory.on_death()
	SaveManager.save_game()

	get_tree().change_scene_to_file("res://death/Death.tscn")

func extract():
	extracted = true
	run_active = false
	successful_extractions += 1
	runs_completed += 1

	# Transfer all loot to stash
	Inventory.on_extract()

	# Check for broken equipment
	Inventory.check_broken_equipment()

	SaveManager.save_game()

	get_tree().change_scene_to_file("res://base/Base.tscn")

func startRun():
	run_active = true
	extracted = false
	refresh()
	tutorialsCompleted = [1, 2, 3]
	setPhase(1)

func getMilesTraveled():
	if cheaterMode:
		return 0
	else:
		return round((distance + currentDistance) * 1000.0)

func setPhase(phase):
	distance += currentDistance
	currentDistance = 0

	# Degrade jump drive on phase transition
	Inventory.degrade_ship_equipment(Items.ShipSlot.JUMP_DRIVE, 1)

	if phase == 1:
		if tutorialsCompleted.has(phase):
			get_tree().change_scene_to_file("res://crash/Crashing.tscn")
		else:
			get_tree().change_scene_to_file("res://crash/Tutorial.tscn")
	elif phase == 2:
		if tutorialsCompleted.has(phase):
			get_tree().change_scene_to_file("res://explore/Exploring.tscn")
		else:
			get_tree().change_scene_to_file("res://explore/Tutorial.tscn")
	elif phase == 3:
		if tutorialsCompleted.has(phase):
			get_tree().change_scene_to_file("res://launch/Launching.tscn")
		else:
			get_tree().change_scene_to_file("res://launch/Tutorial.tscn")

func getMaxAlienFighters():
	return ceil(getMilesTraveled()/10000000.0)

func secret(distance):
	# hahahahahah
	return distance
