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

var debug = true

var dead = false
var deathBy = {cause = null}

var distance = 0
var currentDistance = 0 #distance in current scene

func refresh():
	dead = false
	
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
	
func addFuel(amt):
	self.fuel += amt
	print("new fuel is ", self.fuel)

func die(deathInfo = null):
	if deathInfo:
		deathBy.cause = deathInfo.cause
	else:
		deathBy.cause = Game.DeathBy.Planet
	print("The end")
	
	
	
	var score = (distance + currentDistance) * 1000.0
	print("Score of ", score)
	get_tree().change_scene("res://Menu.tscn")
	# TODO - cut to scene of destruction based on phase?
	
func setPhase(phase):
	distance += currentDistance
	currentDistance = 0
	if phase == 1:
		get_tree().change_scene("res://crash/Crashing.tscn")
	elif phase == 2:
		get_tree().change_scene("res://explore/Exploring.tscn")
	elif phase == 3:
		get_tree().change_scene("res://launch/Launching.tscn")
	