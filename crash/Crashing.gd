extends Node2D

const FALL_SPEED = 1000
const GROUND_OBS_SPEED = 800
const SKY_OBS_SPEED = 900

var mountainScene = load("res://crash/Mountain.tscn")
var junkScene = load("res://crash/Junk.tscn")

var distanceToGround = 39000

var groundDirection = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	Game.health = 100
	distanceToGround = Game.currentPlanet.radius * 1000
	var groundRad =  $GroundObstacles/StartPosition.get_angle_to($GroundObstacles/EndPosition.position)
	groundDirection = Vector2(cos(groundRad), sin(groundRad))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	distanceToGround -= delta * FALL_SPEED
	$DistanceLabel.text = str(round(distanceToGround)) + "ft"
	
	handleGroundSpawn()
	handleGroundMoves(delta)
	
	handleSkySpawn()
	handleSkyMoves(delta)
	
	if distanceToGround < 20000:
		$Ship.stopFireDisplay()
		
	if distanceToGround <= 0:
		crash()

func handleSkySpawn():
	if $SkyObstacles/Timer.time_left <= 0:
		# Yikes, don't judge me
		var junk = junkScene.instance()
		junk.position = $SkyObstacles/StartPositions.get_children()[round(rand_range(0, $SkyObstacles/StartPositions.get_children().size())-1)].position
		var end = $SkyObstacles/EndPositions.get_children()[round(rand_range(0, $SkyObstacles/EndPositions.get_children().size())-1)]
		var junkRads = junk.get_angle_to(end.position)
		junk.direction = Vector2(cos(junkRads), sin(junkRads))
		var scale = rand_range(0.5,1.5)
		junk.scale = Vector2(scale, scale)
		junk.find_node("Area2D").connect("body_entered", self, "hitObstacle")
		$SkyObstacles/Obstacles.add_child(junk)
		$SkyObstacles/Timer.start(rand_range(2,7))
		
func handleSkyMoves(delta):
	for obj in $SkyObstacles/Obstacles.get_children():
		obj.position += obj.direction * SKY_OBS_SPEED*delta
		if obj.position.x < $SkyObstacles/EndPositions.get_children()[0].position.x:
			obj.queue_free()
	
func handleGroundSpawn():
	if Game.currentPlanet.biome == Game.PlanetBiome.Mountain:
		if $GroundObstacles/Timer.time_left <= 0:
			# Yikes, don't judge me
			var mtn = mountainScene.instance()
			mtn.position = $GroundObstacles/StartPosition.position
			mtn.position.x += rand_range(-50,100)
			mtn.position.y += rand_range(-32,32)
			mtn.scale = Vector2(rand_range(0.8,3),rand_range(1,6))
			mtn.find_node("Area2D").connect("body_entered", self, "hitObstacle")
			$GroundObstacles/Obstacles.add_child(mtn)
			$GroundObstacles/Timer.start(rand_range(0.2,3))
	if Game.currentPlanet.biome == Game.PlanetBiome.Forest:
		if distanceToGround < 20000:
			pass #TODO make this a thing
			
			
func handleGroundMoves(delta):
	for obj in $GroundObstacles/Obstacles.get_children():
		obj.position += groundDirection*GROUND_OBS_SPEED*delta
		if obj.position.x < $GroundObstacles/EndPosition.position.x:
			obj.queue_free()

func hitObstacle(body):
	if body.is_in_group("ship"):
		Game.health -= 20
		print("ouch")
		$Ship.showDamage()
		# TODO - play hurt (spark and flash?)
	
	if Game.health <= 0:
		Game.die()
		

func crash():
	# TODO - play crash
	nextPhase()
	
func nextPhase():
	get_tree().change_scene("res://explore/Exploring.tscn")

func _on_DeathArea2D_body_entered(body):
	if body.is_in_group("ship"):
		Game.die()
