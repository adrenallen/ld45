extends Node2D

var item_id: String = ""
var item_quantity: int = 1
var picked_up: bool = false
var bob_time: float = 0.0

func _ready():
	if item_id != "":
		_update_display()

func init(p_item_id: String, p_quantity: int = 1):
	item_id = p_item_id
	item_quantity = p_quantity
	_update_display()

func _process(delta):
	if picked_up:
		return
	# Gentle bobbing animation
	bob_time += delta * 3.0
	$Sprite2D.position.y = sin(bob_time) * 4.0

func _update_display():
	var item_def = Items.get_item(item_id)
	if item_def.is_empty():
		return
	$Label.text = item_def.get("name", "???")
	var rarity = item_def.get("rarity", Items.Rarity.COMMON)
	var color = Items.RARITY_COLORS.get(rarity, Color.WHITE)
	$Label.add_theme_color_override("font_color", color)
	$Sprite2D.modulate = color

func _on_area_2d_body_entered(body):
	if picked_up:
		return
	if body.is_in_group("player"):
		_try_pickup()

func _try_pickup():
	var item_def = Items.get_item(item_id)
	if Inventory.add_to_player_inventory(item_id, item_quantity):
		picked_up = true

		# Degrade backpack on pickup
		Inventory.degrade_player_equipment(Items.EquipSlot.BACKPACK, 1)

		# Spawn floating pickup text at player position
		_spawn_pickup_popup(item_def)

		$AnimationPlayer.play("pickup")
	else:
		# Show "full" indicator with bounce
		$FullLabel.visible = true
		$FullLabel.modulate = Color(1, 0.3, 0.3, 1)
		var tween = create_tween()
		tween.tween_property($FullLabel, "position:y", $FullLabel.position.y - 20, 0.3)
		tween.tween_property($FullLabel, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func(): $FullLabel.visible = false)

func _spawn_pickup_popup(item_def: Dictionary):
	var rarity = item_def.get("rarity", Items.Rarity.COMMON)
	var color = Items.RARITY_COLORS.get(rarity, Color.WHITE)
	var item_name = item_def.get("name", "???")

	# Create floating label in the world
	var popup = Label.new()
	popup.text = "+ %s x%d" % [item_name, item_quantity]
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.add_theme_font_size_override("font_size", 22)
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	popup.add_theme_constant_override("outline_size", 3)
	popup.position = Vector2(-60, -50)
	popup.z_index = 200
	add_child(popup)

	# Animate: float up and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 60, 1.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 1.2).set_delay(0.4)
