extends KinematicBody2D

const THRUST_POWER = 140

const MAX_SPEED = 120

const FUEL_BURN_RATE = 5

export var velocity = Vector2(0,0)
var gravityVelocity = Vector2(0,0)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("mouse_left"):
		if Game.fuel > 0:
			var thrustDir = global_position.direction_to($Camera2D.get_global_mouse_position())
			var thrust = thrustDir.normalized()*THRUST_POWER*delta
			velocity += thrust
			Game.fuel -= FUEL_BURN_RATE*delta	
	
	self.rotation = velocity.angle()
	
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED
		
	if gravityVelocity.length() > MAX_SPEED:
		gravityVelocity = gravityVelocity.normalized() * MAX_SPEED * 0.8
		
	move_and_slide(velocity + gravityVelocity)
	
func getFullVector():
	return (velocity + gravityVelocity).normalized()