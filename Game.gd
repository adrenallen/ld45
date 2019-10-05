extends Node

enum PlanetBiome {
#	Forest,
	Mountain,
#	Mushroom,
#	Gas,
#	Water,
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

func refresh():
	dead = false
	
# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	currentPlanet = generatePlanet()
	print(currentPlanet)
	self.fuel = 80

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("debugger"):
		debug = !debug

func generatePlanet():
	return {
		radius = rand_range(32,96),
		gravity = rand_range(90, 200),
		biome = PlanetBiome.values()[randi()%PlanetBiome.values().size()],
		atmosphereToxicity = rand_range(1,5)
	}
	
func addFuel(amt):
	self.fuel += amt
	print("new fuel is ", self.fuel)

func die():
	print("The end")
	get_tree().change_scene("res://Menu.tscn")
	# TODO - cut to scene of destruction based on phase?