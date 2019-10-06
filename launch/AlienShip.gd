extends KinematicBody2D

const ACCEL = 250.0
const MAX_SPEED = 140.0
const SLOW_MAX_SPEED = 75

const ACTIVATE_DISTANCE = 260
const SLOW_DISTANCE = 225
const STOP_DISTANCE = 120

var missileScene = load("res://launch/AlienMissile.tscn")

var velocity = Vector2(0,0)
var hasReachedPlayer = false
var stunned = false

func _ready():
	pass

func _process(delta):
	if stunned:
		$AnimationPlayer.stop()
		$"alien-ship".frame = 0
		return
	elif !$AnimationPlayer.is_playing():
		$AnimationPlayer.play("jet")
		
	var playerTarget = getPlayer()
	if playerTarget == null:
		return
	if $MissileTimer.time_left <= 0 && !stunned && position.distance_to(playerTarget.position) < ACTIVATE_DISTANCE:
		fireMissile()
		

func _physics_process(delta):
	if stunned:
		return # we dont do anything! stunned!
		
	var playerTarget = getPlayer()
	if playerTarget == null:
		return
	look_at(playerTarget.position)
	var vector = playerTarget.position - position
	velocity += (vector.normalized() * ACCEL)
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED
	
	if position.distance_to(playerTarget.position) < STOP_DISTANCE:
		velocity = Vector2(0,0)	
	elif position.distance_to(playerTarget.position) < SLOW_DISTANCE:
		if velocity.length() > SLOW_MAX_SPEED:
			velocity = velocity.normalized() * SLOW_MAX_SPEED
			
	if position.distance_to(playerTarget.position) < ACTIVATE_DISTANCE and !hasReachedPlayer:
		reachedPlayer()
	
	move_and_slide(velocity)
	
func fireMissile():
	var msl = missileScene.instance()
	msl.velocity = velocity
	msl.rotation = rotation
	msl.global_position = $MissileSpawn.global_position
	get_parent().add_child(msl)
	stunned = true
	$StunTimer.start()
	$MissileTimer.start()
	
func getPlayer():
	var playerList = get_tree().get_nodes_in_group("ship")
	if playerList.size() < 1:
		return null
	else:
		return get_tree().get_nodes_in_group("ship")[0]
	
func reachedPlayer():
	hasReachedPlayer = true
	add_to_group("alien-ship")
	
func unstun():
	stunned = false
	
func stun():
	stunned = true

func _on_StunTimer_timeout():
	unstun()
