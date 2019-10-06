extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	$"air-pocket-bottom".modulate = Game.getCurrentBiomeTint()


func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):
		Game.playerInAirPocket = true

func _on_Area2D_body_exited(body):
	if body.is_in_group("player"):
		Game.playerInAirPocket = false
