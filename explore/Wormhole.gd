extends Node2D

var player_in_range: bool = false

func _ready():
	$Label.text = "Wormhole"
	$ExtractLabel.visible = false

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		_extract()

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		$ExtractLabel.visible = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		$ExtractLabel.visible = false

func _extract():
	Game.extract()
