extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal TransitionIn

@export var transitionPhase = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	setTransitionTitle()
	$AnimationPlayer.play("intro")
	get_tree().paused = true

func _process(delta):
	if Game.quickTransitions:
		$AnimationPlayer.speed_scale = 10

func setTransitionTitle():
	if transitionPhase == 1:
		$CanvasLayer/title.texture = load("res://transition/crash_title.png")
	elif transitionPhase == 2:
		$CanvasLayer/title.texture = load("res://transition/explore_title.png")
	elif transitionPhase == 3:
		$CanvasLayer/title.texture = load("res://transition/launch_title.png")
	else:
		print("TODO - Secret level?")

func fadeIn():
	# Force overlays fully transparent since unpausing stops this node's
	# AnimationPlayer (process_mode = WHEN_PAUSED), leaving them partially visible
	$CanvasLayer/black_bg.modulate = Color(1, 1, 1, 0)
	$CanvasLayer/title.self_modulate = Color(1, 1, 1, 0)
	get_tree().paused = false
	emit_signal("TransitionIn")
