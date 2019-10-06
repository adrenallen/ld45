extends Node2D

var planetScene = load("res://launch/Planet1.tscn")
var sunScene = load("res://launch/Sun.tscn")

var planetName = "N/A"
var distance = 0
var deathBy = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func init():
	if deathBy.cause == Game.DeathBy.Sun:
		var newSun = sunScene.instance()
		$LeaderboardRow/Exhibit.add_child(newSun)
	elif deathBy.cause == Game.DeathBy.Planet:
		var newPlanet = planetScene.instance()
		newPlanet.gravity = 0 # TODO - can we do some magic to turn this on after ship leaves?
		newPlanet.landable = false
		newPlanet.biome = deathBy.biome
		newPlanet.planetRadius = deathBy.radius
		newPlanet.atmosphereToxicity = deathBy.atmosphereToxicity
		$LeaderboardRow/Exhibit.add_child(newPlanet)
		print("Placing planet!")
		
	$LeaderboardRow/DistanceLabel.text = str(distance) + " miles"
	$LeaderboardRow/NameLabel.text = planetName

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
