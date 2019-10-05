extends KinematicBody2D

const THRUST_POWER = 135

const MAX_SPEED = 300

export var velocity = Vector2(0,0)
var gravityVelocity = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("mouse_left"):
		var thrustDir = global_position.direction_to($Camera2D.get_global_mouse_position())
		var thrust = thrustDir.normalized()*THRUST_POWER*delta
		velocity += thrust
	
	
	self.rotation = velocity.angle()
	
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED
		
	if gravityVelocity.length() > MAX_SPEED:
		gravityVelocity = gravityVelocity.normalized() * MAX_SPEED
		
	move_and_slide(velocity + gravityVelocity)
	
	
		
