extends KinematicBody2D

const THRUST_POWER = 190

const MAX_SPEED = 120

const FUEL_BURN_RATE = 5

export var velocity = Vector2(0,0)

var dying = false
# Called when the node enters the scene tree for the first time.
func _ready():
	$Ship.frame = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dying:
		return
	if Input.is_action_pressed("mouse_left"):
		if Game.fuel > 0 or Game.cheaterMode:
			var thrustDir = global_position.direction_to($Camera2D.get_global_mouse_position())
			var thrust = thrustDir.normalized()*THRUST_POWER*delta
			velocity += thrust
			Game.fuel -= FUEL_BURN_RATE*delta
			if Game.fuel < 0:
				Game.fuel = 0
	
	self.rotation = velocity.angle()
	
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED
	move_and_slide(velocity)
	
func getFullVector():
	return (velocity).normalized()
	
func die():
	$AnimationPlayer.play("die")
	dying = true
	remove_from_group("ship")
	
func finishDying():
	Game.die(Game.deathBy)