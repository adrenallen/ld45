extends CharacterBody2D

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

	var move_velocity = Vector2(0,0)
	if Input.is_action_pressed("ui_right"):
		move_velocity.x += ACCEL
	elif Input.is_action_pressed("ui_left"):
		move_velocity.x -= ACCEL

	if Input.is_action_pressed("ui_up"):
		move_velocity.y -= ACCEL
	elif Input.is_action_pressed("ui_down"):
		move_velocity.y += ACCEL

	if move_velocity.length() > MAX_SPEED:
		move_velocity = move_velocity.normalized()
		move_velocity *= MAX_SPEED

	velocity = move_velocity
	move_and_slide()

func die():
	if Game.cheaterMode:
		return
	dying = true
	$AnimationPlayer.play("die")

func endGame():
	Game.die()
