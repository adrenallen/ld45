extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var currentPhase = 1
# Called when the node enters the scene tree for the first time.
func _ready():
	Game.tutorialsCompleted.append(currentPhase)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_Button_pressed():
	Game.setPhase(currentPhase)
