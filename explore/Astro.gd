extends KinematicBody2D

const MAX_SPEED = 300
const ACCEL = 200


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	self.look_at($Camera2D.get_global_mouse_position())
	
	var velocity = Vector2(0,0)
	if Input.is_action_pressed("ui_right"):
		velocity.x += ACCEL
	elif Input.is_action_pressed("ui_left"):
		velocity.x -= ACCEL
		
	if Input.is_action_pressed("ui_up"):
		velocity.y -= ACCEL
	elif Input.is_action_pressed("ui_down"):
		velocity.y += ACCEL
		
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized()
		velocity *= MAX_SPEED
		
	move_and_slide(velocity)