extends StaticBody2D

export var gravity = 120
export var planetRadius = 32
export var biome = Game.PlanetBiome.Mountain
export var atmosphereToxicity = 3


var gravityPullingObjects = []


# Called when the node enters the scene tree for the first time.
func _ready():
	$planet1.transform.x = Vector2(planetRadius/32, 0)
	$planet1.transform.y = Vector2(0, planetRadius/32)
	
	var planetShape = CircleShape2D.new()
	planetShape.set_radius(planetRadius)
	$CollisionShape2D.set_shape(planetShape)

	var gravityShape = CircleShape2D.new()
	gravityShape.set_radius(planetRadius*5)
	$GravityArea2D/CollisionShape2D.set_shape(gravityShape)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for obj in gravityPullingObjects:
		var gravityPull = obj.global_position.direction_to(self.global_position) * gravity * delta
		obj.gravityVelocity += gravityPull


func _on_GravityArea2D_body_entered(body):
	if body.is_in_group("ship"):
		gravityPullingObjects.append(body)
	


func _on_GravityArea2D_body_exited(body):
	gravityPullingObjects.erase(body)
