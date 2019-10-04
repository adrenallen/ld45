extends KinematicBody2D

const MAX_SPEED = 700
const ACCEL = 400

var velocity = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.look_at(get_viewport().get_mouse_position())
	
	if Input.is_action_pressed("ui_right"):
		velocity.x += ACCEL*delta
	elif Input.is_action_pressed("ui_left"):
		velocity.x -= ACCEL*delta
		
	if Input.is_action_pressed("ui_up"):
		velocity.y -= ACCEL*delta
	elif Input.is_action_pressed("ui_down"):
		velocity.y += ACCEL*delta
		
	if velocity.x + velocity.y > MAX_SPEED:
		velocity = velocity.normalized()
		velocity *= MAX_SPEED
		
	move_and_slide(velocity)