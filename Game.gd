extends Node

var fuel = 200
var currentPlanet = {
	gravity = 200,
	radius = 32
} 

# Called when the node enters the scene tree for the first time.
func _ready():
	currentPlanet = generatePlanet()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func generatePlanet():
	return {
		radius = rand_range(32,96),
		gravity = rand_range(90, 200)
	}
