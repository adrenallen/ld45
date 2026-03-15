extends GutTest

# Tests that verify Godot 4 API migration was done correctly.
# These tests check that deprecated Godot 3 APIs are no longer used
# and that Godot 4 equivalents work properly.


func test_gdscript_files_no_old_instance_calls():
	var gd_files = _get_all_gd_files("res://")
	for path in gd_files:
		if path.begins_with("res://addons/") or path.begins_with("res://test/"):
			continue
		var content = FileAccess.get_file_as_string(path)
		assert_true(
			content.find(".instance()") == -1,
			"%s should not contain .instance() (use .instantiate())" % path
		)


func test_gdscript_files_no_old_change_scene():
	var gd_files = _get_all_gd_files("res://")
	for path in gd_files:
		if path.begins_with("res://addons/") or path.begins_with("res://test/"):
			continue
		var content = FileAccess.get_file_as_string(path)
		# Check for change_scene( but not change_scene_to_file(
		var idx = content.find("change_scene(")
		if idx != -1:
			# Make sure it's not change_scene_to_file(
			var before = content.substr(max(0, idx - 8), 8 + 13)
			assert_true(
				before.find("change_scene_to_file(") != -1,
				"%s should use change_scene_to_file() not change_scene()" % path
			)


func test_gdscript_files_no_old_rand_range():
	var gd_files = _get_all_gd_files("res://")
	for path in gd_files:
		if path.begins_with("res://addons/") or path.begins_with("res://test/"):
			continue
		var content = FileAccess.get_file_as_string(path)
		# rand_range is old, randf_range is new
		# Need to check for rand_range but not randf_range
		var idx = 0
		while idx < content.length():
			idx = content.find("rand_range", idx)
			if idx == -1:
				break
			# Check character before - if it's 'f' then it's randf_range (ok)
			if idx > 0 and content[idx - 1] == "f":
				idx += 1
				continue
			assert_true(false,
				"%s still contains old rand_range() call (use randf_range())" % path)
			break


func test_gdscript_files_no_old_deg2rad():
	var gd_files = _get_all_gd_files("res://")
	for path in gd_files:
		if path.begins_with("res://addons/") or path.begins_with("res://test/"):
			continue
		var content = FileAccess.get_file_as_string(path)
		assert_true(
			content.find("deg2rad(") == -1,
			"%s should not contain deg2rad() (use deg_to_rad())" % path
		)


func test_gdscript_files_no_kinematic_body_2d():
	var gd_files = _get_all_gd_files("res://")
	for path in gd_files:
		if path.begins_with("res://addons/") or path.begins_with("res://test/"):
			continue
		var content = FileAccess.get_file_as_string(path)
		assert_true(
			content.find("KinematicBody2D") == -1,
			"%s should not reference KinematicBody2D (use CharacterBody2D)" % path
		)


func test_gdscript_files_no_old_export_syntax():
	var gd_files = _get_all_gd_files("res://")
	for path in gd_files:
		if path.begins_with("res://addons/") or path.begins_with("res://test/"):
			continue
		var content = FileAccess.get_file_as_string(path)
		# Check for "export var" without "@" prefix (old syntax)
		var lines = content.split("\n")
		for line in lines:
			var trimmed = line.strip_edges()
			if trimmed.begins_with("export var") or trimmed.begins_with("export("):
				assert_true(false,
					"%s has old-style 'export var' (should be '@export var')" % path)
				break


func test_gdscript_files_no_pool_arrays():
	var gd_files = _get_all_gd_files("res://")
	for path in gd_files:
		if path.begins_with("res://addons/") or path.begins_with("res://test/"):
			continue
		var content = FileAccess.get_file_as_string(path)
		assert_true(
			content.find("PoolStringArray") == -1,
			"%s should not contain PoolStringArray (use PackedStringArray)" % path
		)
		assert_true(
			content.find("PoolVector2Array") == -1,
			"%s should not contain PoolVector2Array (use PackedVector2Array)" % path
		)


func test_gdscript_files_no_old_json_print():
	var gd_files = _get_all_gd_files("res://")
	for path in gd_files:
		if path.begins_with("res://addons/") or path.begins_with("res://test/"):
			continue
		var content = FileAccess.get_file_as_string(path)
		assert_true(
			content.find("JSON.print(") == -1,
			"%s should not contain JSON.print() (use JSON.stringify())" % path
		)


func test_scene_files_use_format_3():
	var tscn_files = _get_all_files_with_extension("res://", ".tscn")
	for path in tscn_files:
		if path.begins_with("res://addons/"):
			continue
		var content = FileAccess.get_file_as_string(path)
		assert_true(
			content.find("format=3") != -1 or content.find("format = 3") != -1,
			"%s should use format=3 (Godot 4)" % path
		)


func test_scene_files_no_old_kinematic_body():
	var tscn_files = _get_all_files_with_extension("res://", ".tscn")
	for path in tscn_files:
		if path.begins_with("res://addons/"):
			continue
		var content = FileAccess.get_file_as_string(path)
		assert_true(
			content.find('type="KinematicBody2D"') == -1,
			"%s should not have KinematicBody2D type (use CharacterBody2D)" % path
		)


func test_scene_files_no_dynamic_font():
	var tscn_files = _get_all_files_with_extension("res://", ".tscn")
	for path in tscn_files:
		if path.begins_with("res://addons/"):
			continue
		var content = FileAccess.get_file_as_string(path)
		assert_true(
			content.find("DynamicFont") == -1,
			"%s should not have DynamicFont (use FontFile)" % path
		)


func test_scene_files_no_old_sprite_type():
	var tscn_files = _get_all_files_with_extension("res://", ".tscn")
	for path in tscn_files:
		if path.begins_with("res://addons/"):
			continue
		var content = FileAccess.get_file_as_string(path)
		# Check for type="Sprite" but not type="Sprite2D"
		var idx = 0
		while idx < content.length():
			idx = content.find('type="Sprite"', idx)
			if idx == -1:
				break
			assert_true(false,
				"%s has old Sprite type (should be Sprite2D)" % path)
			break


func test_scene_files_use_animation_library():
	var tscn_files = _get_all_files_with_extension("res://", ".tscn")
	for path in tscn_files:
		if path.begins_with("res://addons/"):
			continue
		var content = FileAccess.get_file_as_string(path)
		# If it has animations, it should use AnimationLibrary format
		if content.find("AnimationPlayer") != -1 and content.find("Animation") != -1:
			assert_true(
				content.find("anims/") == -1,
				"%s should not use old anims/ format (use AnimationLibrary)" % path
			)


func test_project_godot_config_version():
	var content = FileAccess.get_file_as_string("res://project.godot")
	assert_true(
		content.find("config_version=5") != -1,
		"project.godot should have config_version=5 for Godot 4"
	)


func test_resource_files_use_format_3():
	var tres_files = _get_all_files_with_extension("res://", ".tres")
	for path in tres_files:
		if path.begins_with("res://addons/"):
			continue
		var content = FileAccess.get_file_as_string(path)
		assert_true(
			content.find("format=3") != -1 or content.find("format = 3") != -1,
			"%s should use format=3 (Godot 4)" % path
		)


# --- Helper functions ---

func _get_all_gd_files(base_path: String) -> Array:
	return _get_all_files_with_extension(base_path, ".gd")


func _get_all_files_with_extension(base_path: String, extension: String) -> Array:
	var files = []
	var dir = DirAccess.open(base_path)
	if dir == null:
		return files
	_scan_dir_recursive(dir, base_path, extension, files)
	return files


func _scan_dir_recursive(dir: DirAccess, base_path: String, extension: String, files: Array):
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = base_path.path_join(file_name)
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				var sub_dir = DirAccess.open(full_path)
				if sub_dir:
					_scan_dir_recursive(sub_dir, full_path, extension, files)
		elif file_name.ends_with(extension):
			files.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()
