extends Node2D

var setShield = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	if Game.shipHealth != setShield:
		setShield = Game.shipHealth
		var shields = $shields.get_children()
		for i in range(shields.size()):
			if i <= setShield-1:
				shields[i].frame = 0
			else:
				shields[i].frame = 1
		
			