extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal TransitionIn

export var transitionPhase = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	setTransitionTitle()
	$AnimationPlayer.play("intro")
	$AnimationPlayer.playback_speed = 10
	get_tree().paused = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func setTransitionTitle():
	if transitionPhase == 1:
		$title.texture = load("res://transition/crash_title.png")
	elif transitionPhase == 2:
		$title.texture = load("res://transition/explore_title.png")
	elif transitionPhase == 3:
		$title.texture = load("res://transition/launch_title.png")
	else:
		print("TODO - Secret level?")

func fadeIn():
	get_tree().paused = false
	emit_signal("TransitionIn")
