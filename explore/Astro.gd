extends KinematicBody2D

const MAX_SPEED = 200
const ACCEL = 10
const DECEL = 8

var velocity = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.look_at($Camera2D.get_global_mouse_position())
	
	if Input.is_action_pressed("ui_right"):
		velocity.x += ACCEL
	elif Input.is_action_pressed("ui_left"):
		velocity.x -= ACCEL
	elif abs(velocity.x) > 0:
		velocity.x = velocity.x - (DECEL * (velocity.x/abs(velocity.x)))
		if abs(velocity.x) <= DECEL:
			velocity.x = 0
		
	if Input.is_action_pressed("ui_up"):
		velocity.y -= ACCEL
	elif Input.is_action_pressed("ui_down"):
		velocity.y += ACCEL
	elif abs(velocity.y) > 0:
		velocity.y = velocity.y - (DECEL * (velocity.y/abs(velocity.y)))
		if abs(velocity.y) <= DECEL:
			velocity.y = 0
		
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized()
		velocity *= MAX_SPEED
		
	move_and_slide(velocity)