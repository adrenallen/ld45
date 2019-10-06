extends Node2D

const LEADERBOARD_URL = Game.BASE_URL + "/leaderboard"
var lbRowScene = load("res://leaderboard/LeaderboardRow.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	print($HTTPRequest.request(LEADERBOARD_URL))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	#[{deathBy:{cause:Null}, distance:0, name:asdfasdf, time:1570334831211}]
	var position = 0
	for lb in json.result:
		var lbr = lbRowScene.instance()
		lbr.planetName = lb.name
		lbr.deathBy = lb.deathBy
		lbr.distance = lb.distance
		lbr.position.y += 55*position
		lbr.z_index = -position
		lbr.init()
		
		$Top10.add_child(lbr)
		
		position += 1
		

func _on_Button_button_up():
	get_tree().change_scene("res://Menu.tscn")
