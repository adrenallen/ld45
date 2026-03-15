extends CharacterBody2D

const THRUST_POWER = 190
const MAX_SPEED = 120
const FUEL_BURN_RATE = 5

var dying = false

func _ready():
	$Ship.frame = 0

func _process(delta):
	if dying:
		return
	if Input.is_action_pressed("mouse_left"):
		if Game.fuel > 0 or Game.cheaterMode:
			var thrustDir = global_position.direction_to($Camera2D.get_global_mouse_position())
			var thrust = thrustDir.normalized()*THRUST_POWER*delta
			velocity += thrust

			var effective_burn = FUEL_BURN_RATE * Game.fuelEfficiency * delta
			Game.fuel -= effective_burn
			if Game.fuel < 0:
				Game.fuel = 0

			# Degrade reactor and fuel tank based on fuel consumed
			Inventory.degrade_ship_equipment(Items.ShipSlot.REACTOR, effective_burn * Inventory.REACTOR_WEAR_RATE)
			Inventory.degrade_ship_equipment(Items.ShipSlot.FUEL_TANK, effective_burn * Inventory.REACTOR_WEAR_RATE)

	self.rotation = velocity.angle()

	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED
	move_and_slide()

func getFullVector():
	return (velocity).normalized()

func die():
	$AnimationPlayer.play("die")
	dying = true
	remove_from_group("ship")

func finishDying():
	Game.die(Game.deathBy)
