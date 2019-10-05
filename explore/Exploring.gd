extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func _process(delta):
	if Input.is_action_just_pressed("debugger"):
		nextPhase()

func nextPhase():
	get_tree().change_scene("res://launch/Launching.tscn")

func _on_Transition_TransitionIn():
	$KinematicBody2D/Camera2D.current = true
