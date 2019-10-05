extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	var map = generateMap()
	for y in range(map.size()):
		for x in range(map[y].size()):
#			print(x, y, map[y][x])
			$TileMap.set_cell(x, y, map[y][x])
			if map[y][x] == 0:
				$KinematicBody2D.global_position = $TileMap.map_to_world(Vector2(x,y))
	
func _process(delta):
	pass

func nextPhase():
	get_tree().change_scene("res://launch/Launching.tscn")

func _on_Transition_TransitionIn():
	$KinematicBody2D/Camera2D.current = true

func generateMapOpen(dimensions):
	var array = []
	for i in range(0, dimensions):
		array.append([])
		for j in range(0, dimensions):
			array[i].append(1)
	return array

func generateMap():
	var dimensions = 128
	var maxTunnels = 60
	var maxLength = 10
	var map = generateMapOpen(dimensions)
	var currentRow = randi()%dimensions
	var currentCol = randi()%dimensions
	
	var directions = [Vector2(-1,0), Vector2(1,0), Vector2(0,-1), Vector2(0,1)]
	var lastDirection = Vector2(0, 0)
	var randomDirection
	
	while maxTunnels > 0:
		randomDirection = directions[randi()%directions.size()]
		while (randomDirection.x == -lastDirection.x and randomDirection.y == -lastDirection.y) or (randomDirection.x == lastDirection.x and randomDirection.y == lastDirection.y):
			randomDirection = directions[randi()%directions.size()]
		
		var randomLength = randi()%maxLength+1
		var tunnelLength = 0
		
		while tunnelLength < randomLength:
			if (
				((currentRow == 0) and (randomDirection.x == -1)) or 
				((currentCol == 0) and (randomDirection.y == -1)) or
				((currentRow == dimensions - 1) and (randomDirection.x == 1)) or
				((currentCol == dimensions - 1) and (randomDirection.y == 1))
			):
				break
			else:
				map[currentRow][currentCol] = 0
				currentRow += randomDirection.x
				currentCol += randomDirection.y
				tunnelLength += 1
		
		if tunnelLength > 0:
			lastDirection = randomDirection
			maxTunnels -= 1
			
	return map