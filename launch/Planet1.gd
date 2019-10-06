extends Node2D

export var gravity = 120
export var planetRadius = 32
export var biome = Game.PlanetBiome.Mountain
export var atmosphereToxicity = 3
export var landable = true


var gravityPullingObjects = []


# Called when the node enters the scene tree for the first time.
func _ready():
	$planet1.transform.x = Vector2(planetRadius/32, 0)
	$planet1.transform.y = Vector2(0, planetRadius/32)
	
	var planetShape = CircleShape2D.new()
	planetShape.set_radius(planetRadius)
	$PlanetArea2D/CollisionShape2D.set_shape(planetShape)

	var gravityShape = CircleShape2D.new()
	gravityShape.set_radius(planetRadius*5)
	$GravityArea2D/CollisionShape2D.set_shape(gravityShape)
	
	setPlanetImage()
	
func setPlanetImage():
	$planet1.hframes = 1
	$planet1.frame = 0
	$AnimationPlayer.stop()
	
	if biome == Game.PlanetBiome.Mountain:
		$planet1.texture = load("res://launch/planet_mountain.png")
	elif biome == Game.PlanetBiome.Forest:
		$planet1.texture = load("res://launch/planet_forest.png")
	elif biome == Game.PlanetBiome.Fungal:
		$planet1.texture = load("res://launch/planet_fungal.png")
	elif biome == Game.PlanetBiome.Water:
		$planet1.texture = load("res://launch/planet_water.png")
	elif biome == Game.PlanetBiome.Gas:
		$planet1.texture = load("res://launch/planet_gas.png")
		$planet1.hframes = 5
		$AnimationPlayer.play("gas_idle")
	elif biome == Game.PlanetBiome.Lava:
		$planet1.texture = load("res://launch/planet_lava.png")
		
	var atmoFactor = atmosphereToxicity/Game.MAX_ATMO_TOXIC
	if atmoFactor > 0.75:
		$planet1.modulate *= 0.65
		$planet1.modulate.g = 1
	elif atmoFactor > 0.5:
		$planet1.modulate *= 0.8
		$planet1.modulate.r = 1
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for obj in gravityPullingObjects:
		var gravityPull = obj.global_position.direction_to(self.global_position) * gravity * delta
		obj.velocity += gravityPull


func _on_GravityArea2D_body_entered(body):
	if body.is_in_group("ship") or body.is_in_group("alien-ship"):
		gravityPullingObjects.append(body)
	


func _on_GravityArea2D_body_exited(body):
	gravityPullingObjects.erase(body)


func _on_PlanetArea2D_body_entered(body):
	if body.is_in_group("ship"):
		if self.landable:
			Game.setPlanet(self)
			Game.setPhase(1)


func _on_PlanetArea2D_area_entered(area):
	# Only destroy if landable, if not landable it's probably leaderboard instance
	if landable:
		if area.is_in_group("planet"):
			queue_free()
