extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const MAX_FUEL_SCALE = 3.96
var planetScene = load("res://launch/Planet1.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	$Ship.global_position = $LaunchPlanet/planet1.global_position
	$Ship.global_position.y -= $LaunchPlanet.planetRadius
	$LaunchPlanet.gravity = 0 # TODO - can we do some magic to turn this on after ship leaves?
	
	generateGalaxy()
	
func generateGalaxy():
	pass
	
	
func _process(delta):
	$UI.global_position = $Ship/Camera2D.get_camera_position()
	$UI.global_position.x -= get_viewport_rect().size.x/2
	$UI.global_position.y -= get_viewport_rect().size.y/2
	
	$"UI/fuel-icon/fuel-body".scale.x = Game.fuel / 100.0 * MAX_FUEL_SCALE

func nextPhase():
	get_tree().change_scene("res://crash/Crashing.tscn")


func _on_TransitionIn_TransitionIn():
	$Ship/Camera2D.current = true