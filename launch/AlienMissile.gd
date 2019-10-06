extends KinematicBody2D

const ACCEL = 100
const MAX_SPEED = 150.0

var velocity = Vector2(0,0)
var isExploding = false

func _ready():
	pass

func _physics_process(delta):
	self.rotation = velocity.angle()
	
	var player = getPlayer()
	if player == null:
		return
		
	if !isExploding:
		var vector = player.position - position
		var thrust = vector.normalized()*ACCEL*delta
		velocity += thrust
	
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED
	
	move_and_slide(velocity)
	
func getPlayer():
	var playerList = get_tree().get_nodes_in_group("ship")
	if playerList.size() < 1:
		return null
	else:
		return get_tree().get_nodes_in_group("ship")[0]


func explode():
	isExploding = true
	$"alien-missile/AnimationPlayer".play("explode")

func _on_ExplodeTimer_timeout():
	explode()

var hasDoneDamage = false
func _on_Area2D_body_entered(body):
	if hasDoneDamage:
		return
	if body.is_in_group("ship"):
		Game.shipHealth -= 1
		hasDoneDamage = true
		if Game.shipHealth <= 0:
			Game.deathBy = {cause = Game.DeathBy.AlienShip}
			body.die()
		explode()
		
