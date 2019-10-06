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
	Planet
}

var fuel = 0
var oxygen = 100
var health = 100

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

var distance = 0
var currentDistance = 0 #distance in current scene

func refresh():
	dead = false
	deathBy = {cause = null}
	planetsLandedOn = 0
	health = 100
	fuel = 0
	oxygen = 100
	
# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	currentPlanet = generatePlanet()
	self.fuel = 80

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("debugger"):
		debug = !debug

func generatePlanet():
	return {
		radius = rand_range(16,64),
		gravity = rand_range(20, 80),
		biome = PlanetBiome.values()[randi()%PlanetBiome.values().size()],
		atmosphereToxicity = rand_range(1,5)
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
	self.fuel += amt

func die(deathInfo = null):
	if deathInfo:
		deathBy = deathInfo
	else:
		deathBy.biome = Game.currentPlanet.biome
		deathBy.radius = Game.currentPlanet.radius
		deathBy.atmosphereToxicity = Game.currentPlanet.atmosphereToxicity
		deathBy.cause = Game.DeathBy.Planet
			
	get_tree().change_scene("res://death/Death.tscn")
	
func getMilesTraveled():
	return round((distance + currentDistance) * 1000.0)

func setPhase(phase):
	distance += currentDistance
	currentDistance = 0
	if phase == 1:
		get_tree().change_scene("res://crash/Crashing.tscn")
	elif phase == 2:
		get_tree().change_scene("res://explore/Exploring.tscn")
	elif phase == 3:
		get_tree().change_scene("res://launch/Launching.tscn")
		
func secret(distance):
	# hahahahahah
	return distance
	