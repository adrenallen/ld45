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
	AlienShip
}

const MAX_ATMO_TOXIC = 5
const AIR_POCKET_OXYGEN_RATE = 5
const MAX_SHIP_HEALTH = 5
const BASE_URL = "https://ld45.garrettallen.dev/lb"
#const BASE_URL = "http://18.224.157.46:5000"

var fuel = 0
var oxygen = 100
var shipHealth = MAX_SHIP_HEALTH
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

func refresh():
	randomize()
	
	dead = false
	deathBy = {cause = null}
	planetsLandedOn = 0
	shipHealth = MAX_SHIP_HEALTH
	fuel = 20
	oxygen = 100
	playerInAirPocket = false
	
	setFirstPlanet()

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
		radius = rand_range(16,64),
		gravity = rand_range(20, 80),
		biome = PlanetBiome.values()[randi()%PlanetBiome.values().size()],
		atmosphereToxicity = rand_range(1,MAX_ATMO_TOXIC)
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
	if fuel < 100:
		fuel += amt

func repairShip():
	if shipHealth != MAX_SHIP_HEALTH:
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
			
	get_tree().change_scene("res://death/Death.tscn")
	
func getMilesTraveled():
	if cheaterMode:
		return 0
	else:
		return round((distance + currentDistance) * 1000.0)

func setPhase(phase):
	distance += currentDistance
	currentDistance = 0
	if phase == 1:
		if tutorialsCompleted.has(phase):
			get_tree().change_scene("res://crash/Crashing.tscn")
		else:
			get_tree().change_scene("res://crash/Tutorial.tscn")
	elif phase == 2:
		if tutorialsCompleted.has(phase):
			get_tree().change_scene("res://explore/Exploring.tscn")
		else:
			get_tree().change_scene("res://explore/Tutorial.tscn")
	elif phase == 3:
		if tutorialsCompleted.has(phase):
			get_tree().change_scene("res://launch/Launching.tscn")
		else:
			get_tree().change_scene("res://launch/Tutorial.tscn")

func getMaxAlienFighters():
	return ceil(getMilesTraveled()/10000000.0)

func secret(distance):
	# hahahahahah
	return distance
	