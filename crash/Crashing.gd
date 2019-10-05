extends Node2D

const FALL_SPEED = 1000
const GROUND_OBS_SPEED = 800

var mountainScene = load("res://crash/Mountain.tscn")

var distanceToGround = 39000
var health = 100 # always start at full health

var groundDirection = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	distanceToGround = Game.currentPlanet.radius * 1000
	var groundRad =  $GroundObstacles/StartPosition.get_angle_to($GroundObstacles/EndPosition.position)
	groundDirection = Vector2(cos(groundRad), sin(groundRad))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	distanceToGround -= delta * FALL_SPEED
	$DistanceLabel.text = str(round(distanceToGround)) + "ft"
	
	handleGroundSpawn()
	handleGroundMoves(delta)
	
	
	if Input.is_action_just_pressed("debugger"):
		nextPhase()
		
	if distanceToGround <= 0:
		crash()
		
func handleGroundSpawn():
	if Game.currentPlanet.biome == Game.PlanetBiome.Mountain:
		if $GroundObstacles/Timer.time_left <= 0:
			# Yikes, don't judge me
			var mtn = mountainScene.instance()
			mtn.position = $GroundObstacles/StartPosition.position
			mtn.position.x += rand_range(-50,100)
			mtn.position.y += rand_range(-32,32)
			mtn.scale = Vector2(rand_range(0.8,3),rand_range(1,6))
			mtn.find_node("Area2D").connect("body_entered", self, "hitGroundObstacle")
			$GroundObstacles/Obstacles.add_child(mtn)
			$GroundObstacles/Timer.start(rand_range(0.2,3))
#	if Game.currentPlanet.biome == Game.PlanetBiome.Forest:
#		if distanceToGround < 20000:
			
			
func handleGroundMoves(delta):
	for obj in $GroundObstacles/Obstacles.get_children():
		obj.position += groundDirection*GROUND_OBS_SPEED*delta
		if obj.position.x < $GroundObstacles/EndPosition.position.x:
			obj.queue_free()

func hitGroundObstacle(body):
	if body.is_in_group("ship"):
		health -= 20
		print("ouch")
		$Ship.showDamage()
		# TODO - play hurt (spark and flash?)
	
	if health <= 0:
		Game.die()
		

func crash():
	# TODO - play crash
	nextPhase()
	
func nextPhase():
	get_tree().change_scene("res://explore/Exploring.tscn")

func _on_DeathArea2D_body_entered(body):
	if body.is_in_group("ship"):
		Game.die()
