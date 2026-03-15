extends Node2D

var item_id: String = ""
var item_quantity: int = 1
var picked_up: bool = false

func init(p_item_id: String, p_quantity: int = 1):
	item_id = p_item_id
	item_quantity = p_quantity
	_update_display()

func _ready():
	if item_id != "":
		_update_display()

func _update_display():
	var item_def = Items.get_item(item_id)
	if item_def.is_empty():
		return
	var rarity = item_def.get("rarity", Items.Rarity.COMMON)
	$Sprite2D.modulate = Items.RARITY_COLORS.get(rarity, Color.WHITE)

func _on_area_2d_body_entered(body):
	if picked_up:
		return
	if body.is_in_group("ship"):
		if Inventory.add_to_ship_cargo(item_id, item_quantity):
			picked_up = true
			queue_free()
