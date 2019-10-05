extends KinematicBody2D

const MAX_SPEED = 300
const ACCEL = 500
const DECEL = 1500

var velocity = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.look_at($Camera2D.get_global_mouse_position())
	
	if Input.is_action_pressed("ui_right"):
		velocity.x += ACCEL*delta
	elif Input.is_action_pressed("ui_left"):
		velocity.x -= ACCEL*delta
	elif abs(velocity.x) > 0:
		velocity.x = velocity.x - (DECEL*delta * (velocity.x/abs(velocity.x)))
		if abs(velocity.x) <= DECEL*delta:
			velocity.x = 0
		
	if Input.is_action_pressed("ui_up"):
		velocity.y -= ACCEL*delta
	elif Input.is_action_pressed("ui_down"):
		velocity.y += ACCEL*delta
	elif abs(velocity.y) > 0:
		velocity.y = velocity.y - (DECEL*delta * (velocity.y/abs(velocity.y)))
		if abs(velocity.y) <= DECEL*delta:
			velocity.y = 0
		
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized()
		velocity *= MAX_SPEED
		
	move_and_slide(velocity)