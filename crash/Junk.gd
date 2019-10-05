extends Node2D


var direction = Vector2(0,0)
var rotationRate = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	rotationRate = rand_range(1,100)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.rotate(deg2rad(rotationRate)*delta)
