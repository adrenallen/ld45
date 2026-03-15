extends Control

var current_tab = 0

# Color palette
const COL_BG_DARK = Color(0.06, 0.07, 0.11, 0.92)
const COL_BG_PANEL = Color(0.1, 0.12, 0.18, 0.85)
const COL_ACCENT = Color(0.34, 0.65, 1.0)
const COL_ACCENT_DIM = Color(0.2, 0.35, 0.55)
const COL_GOLD = Color(1.0, 0.78, 0.3)
const COL_TEXT = Color(0.78, 0.82, 0.88)
const COL_TEXT_DIM = Color(0.45, 0.5, 0.58)
const COL_GREEN = Color(0.25, 0.85, 0.4)
const COL_RED = Color(0.95, 0.3, 0.25)

func _ready():
	_apply_theme()
	_show_tab(3)  # Default to Launch tab
	_update_stats()

	if Game.extracted:
		$ExtractionPopup.visible = true
		Game.extracted = false

func _apply_theme():
	# Header panel
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.05, 0.06, 0.1, 0.95)
	header_style.border_color = COL_ACCENT_DIM
	header_style.border_width_bottom = 1
	$HeaderPanel.add_theme_stylebox_override("panel", header_style)

	# Menu button
	_style_button($HeaderPanel/MenuBtn, Color(0.6, 0.3, 0.3), 11)

	# Tab buttons
	var tab_colors = [COL_GOLD, COL_ACCENT, Color(0.6, 0.85, 0.5), COL_GREEN]
	var tab_btns = [$TabBar/StashBtn, $TabBar/LoadoutBtn, $TabBar/CraftingBtn, $TabBar/LaunchBtn]
	for i in range(4):
		_style_tab_button(tab_btns[i], tab_colors[i])

	# Extraction popup
	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.08, 0.12, 0.08, 0.97)
	popup_style.border_color = COL_GREEN
	popup_style.set_border_width_all(2)
	popup_style.set_corner_radius_all(6)
	$ExtractionPopup.add_theme_stylebox_override("panel", popup_style)

	# Launch button
	_style_button($LaunchTab/LaunchButton, COL_GREEN, 20)

func _style_button(btn: Button, color: Color, font_size: int = 12):
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.8)
	normal.border_color = Color(color.r * 0.6, color.g * 0.6, color.b * 0.6, 0.6)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	normal.set_content_margin_all(6)
	btn.add_theme_stylebox_override("normal", normal)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(color.r * 0.3, color.g * 0.3, color.b * 0.3, 0.9)
	hover.border_color = color
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(3)
	hover.set_content_margin_all(6)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(color.r * 0.15, color.g * 0.15, color.b * 0.15, 0.95)
	pressed.border_color = color
	pressed.set_border_width_all(1)
	pressed.set_corner_radius_all(3)
	pressed.set_content_margin_all(6)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))

func _style_tab_button(btn: Button, color: Color):
	_style_button(btn, color, 13)

	# Disabled = active tab
	var active = StyleBoxFlat.new()
	active.bg_color = Color(color.r * 0.15, color.g * 0.15, color.b * 0.15, 0.95)
	active.border_color = color
	active.border_width_bottom = 2
	active.border_width_top = 1
	active.border_width_left = 1
	active.border_width_right = 1
	active.set_corner_radius_all(3)
	active.corner_radius_bottom_left = 0
	active.corner_radius_bottom_right = 0
	active.set_content_margin_all(6)
	btn.add_theme_stylebox_override("disabled", active)
	btn.add_theme_color_override("font_disabled_color", color)

func _show_tab(tab_index: int):
	current_tab = tab_index
	$StashTab.visible = (tab_index == 0)
	$LoadoutTab.visible = (tab_index == 1)
	$CraftingTab.visible = (tab_index == 2)
	$LaunchTab.visible = (tab_index == 3)

	for i in range(4):
		$TabBar.get_child(i).disabled = (i == tab_index)

	match tab_index:
		0: $StashTab.refresh()
		1: $LoadoutTab.refresh()
		2: $CraftingTab.refresh()
		3: $LaunchTab.refresh()

func _update_stats():
	$HeaderPanel/StatsLabel.text = "Runs: %d    Extractions: %d    Deaths: %d    Crafted: %d" % [
		Game.runs_completed, Game.successful_extractions, Game.runs_died, Game.items_crafted
	]

func _on_stash_button_pressed():
	_show_tab(0)

func _on_loadout_button_pressed():
	_show_tab(1)

func _on_crafting_button_pressed():
	_show_tab(2)

func _on_launch_button_pressed():
	_show_tab(3)

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://Menu.tscn")

func _on_extraction_popup_close():
	$ExtractionPopup.visible = false

# Helper to create styled panels usable by tab scripts
static func make_section_panel(color: Color = COL_BG_PANEL) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(color.r + 0.1, color.g + 0.1, color.b + 0.15, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	return style

static func make_slot_panel(color: Color, filled: bool = true) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	if filled:
		style.bg_color = Color(color.r * 0.12, color.g * 0.12, color.b * 0.12, 0.7)
		style.border_color = Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, 0.5)
	else:
		style.bg_color = Color(0.08, 0.08, 0.12, 0.5)
		style.border_color = Color(0.2, 0.2, 0.25, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(6)
	return style
