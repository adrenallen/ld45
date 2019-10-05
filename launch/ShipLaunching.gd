extends KinematicBody2D

const THRUST_POWER = 100

export var velocity = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	print(delta)
	if Input.is_action_pressed("mouse_left"):
		var thrustDir = global_position.direction_to($Camera2D.get_global_mouse_position())
		var thrust = thrustDir.normalized()*THRUST_POWER*delta
		velocity += thrust
	move_and_slide(velocity)
	
		
