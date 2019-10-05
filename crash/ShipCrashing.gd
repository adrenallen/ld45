extends KinematicBody2D

const MAX_SHIP_SPEED_H = 300
const MAX_SHIP_SPEED_V = 450 # TODO - change by planet?

const SHIP_ACCEL_H = 350
const SHIP_ACCEL_V = 900

const SHIP_DECEL_H = 150

const SHIP_FALL_RATE = 100

var velocity = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Planet gravity is ", SHIP_FALL_RATE+Game.currentPlanet.gravity)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity.y += (SHIP_FALL_RATE+Game.currentPlanet.gravity)*delta
	if Input.is_action_pressed("ui_right"):
		velocity.x += SHIP_ACCEL_H*delta
	elif Input.is_action_pressed("ui_left"):
		velocity.x -= SHIP_ACCEL_H*delta
	elif abs(velocity.x) > 0:
		velocity.x = velocity.x - (SHIP_DECEL_H*delta * (velocity.x/abs(velocity.x)))
		if abs(velocity.x) <= SHIP_DECEL_H*delta:
			velocity.x = 0
		
	if Input.is_action_pressed("ui_up"):
		velocity.y -= SHIP_ACCEL_V*delta
	elif Input.is_action_pressed("ui_down"):
		velocity.y += SHIP_ACCEL_V*delta
		
	if abs(velocity.x) > MAX_SHIP_SPEED_H:
		velocity.x = MAX_SHIP_SPEED_H * velocity.x / abs(velocity.x)
		
	if abs(velocity.y) > MAX_SHIP_SPEED_V:
		velocity.y = MAX_SHIP_SPEED_V * velocity.y / abs(velocity.y)
	
	move_and_slide(velocity)

func stopFireDisplay():
	$"ship-side-fire/AnimationPlayer".stop()
	$"ship-side-fire".hide()

func showDamage():
	$AnimationPlayer.play("damage")
	
	
