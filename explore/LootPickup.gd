extends Node2D

var item_id: String = ""
var item_quantity: int = 1
var picked_up: bool = false

func _ready():
	if item_id != "":
		_update_display()

func init(p_item_id: String, p_quantity: int = 1):
	item_id = p_item_id
	item_quantity = p_quantity
	_update_display()

func _update_display():
	var item_def = Items.get_item(item_id)
	if item_def.is_empty():
		return
	$Label.text = item_def.get("name", "???")
	var rarity = item_def.get("rarity", Items.Rarity.COMMON)
	$Label.add_theme_color_override("font_color", Items.RARITY_COLORS.get(rarity, Color.WHITE))

	# Tint the sprite based on rarity
	$Sprite2D.modulate = Items.RARITY_COLORS.get(rarity, Color.WHITE)

func _on_area_2d_body_entered(body):
	if picked_up:
		return
	if body.is_in_group("player"):
		_try_pickup()

func _try_pickup():
	if Inventory.add_to_player_inventory(item_id, item_quantity):
		picked_up = true

		# Degrade backpack on pickup
		Inventory.degrade_player_equipment(Items.EquipSlot.BACKPACK, 1)

		$AnimationPlayer.play("pickup")
	else:
		# Show "full" indicator briefly
		$FullLabel.visible = true
		get_tree().create_timer(1.5).timeout.connect(func(): $FullLabel.visible = false)
