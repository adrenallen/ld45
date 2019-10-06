extends KinematicBody2D

const MAX_SPEED = 300
const ACCEL = 200

var dying = false
# Called when the node enters the scene tree for the first time.
func _ready():
	$"astro-top".frame = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if dying:
		return
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
	
func die():
	dying = true
	$AnimationPlayer.play("die")
	
func endGame():
	Game.die()