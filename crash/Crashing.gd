extends Node2D

const FALL_SPEED = 1000
const GROUND_OBS_SPEED = 700
const SKY_OBS_SPEED = 800

var mountainScene = load("res://crash/Mountain.tscn")
var forestScene = load("res://crash/Forest.tscn")
var fungalScene = load("res://crash/Fungal.tscn")
var lavaScene = load("res://crash/Lava.tscn")
var gasScene = load("res://crash/Gas.tscn")
var waterScene = load("res://crash/Water.tscn")

var junkScene = load("res://crash/Junk.tscn")

var distanceToGround = 39000

var groundDirection = Vector2(0,0)

var inSpace = true
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	distanceToGround = Game.currentPlanet.radius * 1000
	var groundRad =  $GroundObstacles/StartPosition.get_angle_to($GroundObstacles/EndPosition.position)
	groundDirection = Vector2(cos(groundRad), sin(groundRad))
	
	setBGColor()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	distanceToGround -= delta * FALL_SPEED
	$DistanceLabel.text = str(round(distanceToGround)) + " ft"
	
	handleGroundSpawn()
	handleGroundMoves(delta)
	
	handleSkySpawn()
	handleSkyMoves(delta)
		
	if distanceToGround < 20000:
		$Ship.stopFireDisplay()
	
	if distanceToGround < 35000 and inSpace:
		inSpace = false
		$space/AnimationPlayer.play("space_fade")
		
	if distanceToGround < 15000:
		$horizon.position.y -= delta*75
		$horizon.position.x -= delta*30
		
	if distanceToGround <= 0:
		crash()

func setBGColor():
	var bgColor = Game.getCurrentBiomeTint()
	
	$sky_bg.self_modulate = bgColor
	
	#color fg for horizon show up
	bgColor *= .85
	bgColor.a = 1
	$horizon.self_modulate = bgColor
		
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
	if inSpace:
		return #no ground in space bro
	var sceneToUse
	if Game.currentPlanet.biome == Game.PlanetBiome.Mountain:
		sceneToUse = mountainScene
	elif Game.currentPlanet.biome == Game.PlanetBiome.Forest:
		sceneToUse = forestScene
	elif Game.currentPlanet.biome == Game.PlanetBiome.Fungal:
		sceneToUse = fungalScene
	elif Game.currentPlanet.biome == Game.PlanetBiome.Water:
		sceneToUse = waterScene
	elif Game.currentPlanet.biome == Game.PlanetBiome.Gas:
		sceneToUse = gasScene
	elif Game.currentPlanet.biome == Game.PlanetBiome.Lava:
		sceneToUse = lavaScene
		
	if sceneToUse != null:
		if $GroundObstacles/Timer.time_left <= 0:
			# Yikes, don't judge me
			var mtn = sceneToUse.instance()
			mtn.position = $GroundObstacles/StartPosition.position
			mtn.position.x += rand_range(-50,100)
			mtn.position.y += rand_range(-32,32)
			mtn.scale = Vector2(rand_range(0.8,3),rand_range(1,6))
			mtn.find_node("Area2D").connect("body_entered", self, "hitObstacle")
			$GroundObstacles/Obstacles.add_child(mtn)
			$GroundObstacles/Timer.start(rand_range(0.2,3))

func handleGroundMoves(delta):
	for obj in $GroundObstacles/Obstacles.get_children():
		obj.position += groundDirection*GROUND_OBS_SPEED*delta
		if obj.position.x < $GroundObstacles/EndPosition.position.x:
			obj.queue_free()

func hitObstacle(body):
	if body.is_in_group("ship"):
		$Ship/ObstacleHitAudio.play()
		Game.shipHealth -= 1
		$Ship.showDamage()
		# TODO - play hurt (spark and flash?)
	
	if Game.shipHealth <= 0:
		$Ship.die()
		

func crash():
	set_process(false)
	$Ship.set_process(false)
	$AnimationPlayer.play("crash")
	
func nextPhase():
	Game.setPhase(2)

func _on_DeathArea2D_body_entered(body):
	if body.is_in_group("ship"):
		$Ship.die()
