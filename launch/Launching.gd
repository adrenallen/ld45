extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const MAX_FUEL_SCALE = 3.96
var planetScene = load("res://launch/Planet1.tscn")
var sunScene = load("res://launch/Sun.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	$Ship.global_position = $LaunchPlanet/planet1.global_position
	$Ship.global_position.y -= $LaunchPlanet.planetRadius
	$LaunchPlanet.gravity = 0 # TODO - can we do some magic to turn this on after ship leaves?
	$LaunchPlanet.landable = false
	generateGalaxy(800, 0)
	
# Generate a galaxy with a center at point x,y
func generateGalaxy(x,y,planets = 10, maxPlanetDistance = 500):
	var sun = sunScene.instance()
	sun.global_position = Vector2(x,y)
	$Planets.add_child(sun)
	
	var lastPlanetDistance = 150
	for i in range(planets):
		var randomDegree = randi()%360
		var randomRad = deg2rad(randomDegree)
		var planetVector = Vector2(cos(randomRad), sin(randomRad))		
		var newPlanet = newPlanetNode(x,y)			
		var planetDistance = lastPlanetDistance + rand_range(2*newPlanet.planetRadius, 5*newPlanet.planetRadius)
		if planetDistance > maxPlanetDistance:
			planetDistance = maxPlanetDistance
		
		newPlanet.global_position += planetVector.normalized()*planetDistance
		$Planets.add_child(newPlanet)
		lastPlanetDistance = planetDistance
		

func newPlanetNode(x=0,y=0):
	var planetInfo = Game.generatePlanet()
	var newPlanet = planetScene.instance()
	newPlanet.gravity = planetInfo.gravity
	newPlanet.planetRadius = planetInfo.radius
	newPlanet.biome = planetInfo.biome
	newPlanet.atmosphereToxicity = planetInfo.atmosphereToxicity
	newPlanet.global_position.x = x
	newPlanet.global_position.y = y
	return newPlanet
	
func _process(delta):
	$UI.global_position = $Ship/Camera2D.get_camera_position()
	$UI.global_position.x -= get_viewport_rect().size.x/2
	$UI.global_position.y -= get_viewport_rect().size.y/2
	
	$"UI/fuel-icon/fuel-body".scale.x = Game.fuel / 100.0 * MAX_FUEL_SCALE

func nextPhase():
	get_tree().change_scene("res://crash/Crashing.tscn")


func _on_TransitionIn_TransitionIn():
	$Ship/Camera2D.current = true