extends KinematicBody2D

const ACCEL = 120
const MAX_SPEED = 128.0

var velocity = Vector2(0,0)

func _ready():
	pass

func _physics_process(delta):
	self.rotation = velocity.angle()
	
	var player = getPlayer()
	if player == null:
		return
	var vector = player.position - position
	var thrust = vector.normalized()*ACCEL*delta
	velocity += thrust
	
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED
	
	move_and_slide(velocity)
	
func getPlayer():
	var playerList = get_tree().get_nodes_in_group("ship")
	if playerList.size() < 1:
		queue_free()
		return null
	else:
		return get_tree().get_nodes_in_group("ship")[0]

func explode():
	# TODO = explodey boi
	queue_free()

func _on_ExplodeTimer_timeout():
	explode()


func _on_Area2D_body_entered(body):
	if body.is_in_group("ship"):
		Game.shipHealth -= 1
		if Game.shipHealth < 0:
			Game.die({cause = Game.DeathBy.AlienShip})
		explode()
		
