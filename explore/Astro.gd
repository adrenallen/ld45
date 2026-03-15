extends CharacterBody2D

const BASE_MAX_SPEED = 300
const BASE_ACCEL = 200

var dying = false
var last_position = Vector2.ZERO

func _ready():
	$"astro-top".frame = 0
	last_position = global_position

func _physics_process(delta):
	if dying:
		return
	self.look_at($Camera2D.get_global_mouse_position())

	var effective_max_speed = BASE_MAX_SPEED * Game.speedModifier
	var effective_accel = BASE_ACCEL * Game.speedModifier

	var move_velocity = Vector2(0,0)
	if Input.is_action_pressed("ui_right"):
		move_velocity.x += effective_accel
	elif Input.is_action_pressed("ui_left"):
		move_velocity.x -= effective_accel

	if Input.is_action_pressed("ui_up"):
		move_velocity.y -= effective_accel
	elif Input.is_action_pressed("ui_down"):
		move_velocity.y += effective_accel

	if move_velocity.length() > effective_max_speed:
		move_velocity = move_velocity.normalized()
		move_velocity *= effective_max_speed

	velocity = move_velocity
	move_and_slide()

	# Degrade boots based on distance walked
	var dist_moved = global_position.distance_to(last_position)
	if dist_moved > 0.1:
		Inventory.degrade_player_equipment(Items.EquipSlot.BOOTS, dist_moved * Inventory.BOOT_WEAR_RATE)
	last_position = global_position

func die():
	if Game.cheaterMode:
		return
	dying = true
	$AnimationPlayer.play("die")

func endGame():
	Game.die({cause = Game.DeathBy.Suffocation, biome = Game.currentPlanet.biome, radius = Game.currentPlanet.radius, atmosphereToxicity = Game.currentPlanet.atmosphereToxicity, gravity = Game.currentPlanet.gravity})
