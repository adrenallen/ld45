extends Node

var fuel = 200
var currentPlanet = {
	gravity = 200,
	radius = 32,
	biome = PlanetBiome.Forest
} 

enum PlanetBiome {
	Forest,
	Mountain
}

var dead = false

func refresh():
	dead = false
	
# Called when the node enters the scene tree for the first time.
func _ready():
	currentPlanet = generatePlanet()
	print(currentPlanet)
	print(currentPlanet.biome == PlanetBiome.Mountain)
	print(currentPlanet.biome == PlanetBiome.Forest)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func generatePlanet():
	return {
		radius = rand_range(32,96),
		gravity = rand_range(90, 200),
		biome = PlanetBiome.values()[randi()%PlanetBiome.values().size()]
	}

func die():
	print("The end")
	# TODO - cut to scene of destruction based on phase?