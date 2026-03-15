extends GutTest

# Tests that verify Godot 4 specific APIs work correctly.
# These confirm the migrated code uses proper Godot 4 patterns.


func test_character_body_2d_has_velocity():
	var body = CharacterBody2D.new()
	add_child_autofree(body)
	# In Godot 4, velocity is a built-in property of CharacterBody2D
	assert_true("velocity" in body, "CharacterBody2D should have velocity property")
	body.velocity = Vector2(100, 200)
	assert_eq(body.velocity, Vector2(100, 200), "velocity should be settable")


func test_packed_string_array():
	# Verify PackedStringArray works (replacement for PoolStringArray)
	var arr = PackedStringArray()
	arr.append("test")
	assert_eq(arr.size(), 1, "PackedStringArray should work")
	assert_eq(arr[0], "test", "PackedStringArray element access should work")


func test_packed_vector2_array():
	var arr = PackedVector2Array()
	arr.append(Vector2(1, 2))
	assert_eq(arr.size(), 1, "PackedVector2Array should work")
	assert_eq(arr[0], Vector2(1, 2), "PackedVector2Array element access should work")


func test_json_stringify():
	var data = {"key": "value", "number": 42}
	var result = JSON.stringify(data)
	assert_not_null(result, "JSON.stringify should return a string")
	assert_true(result.length() > 0, "JSON.stringify result should not be empty")


func test_json_parse_new_api():
	var json = JSON.new()
	var err = json.parse('{"key": "value", "number": 42}')
	assert_eq(err, OK, "JSON.parse should return OK")
	var data = json.get_data()
	assert_eq(data["key"], "value", "Parsed key should match")
	assert_eq(data["number"], 42, "Parsed number should match")


func test_randf_range():
	for i in range(100):
		var val = randf_range(10.0, 20.0)
		assert_true(val >= 10.0 and val <= 20.0,
			"randf_range should return value in range, got: %s" % val)


func test_deg_to_rad():
	assert_almost_eq(deg_to_rad(180.0), PI, 0.0001, "180 degrees should be PI radians")
	assert_almost_eq(deg_to_rad(90.0), PI / 2.0, 0.0001, "90 degrees should be PI/2 radians")
	assert_almost_eq(deg_to_rad(0.0), 0.0, 0.0001, "0 degrees should be 0 radians")


func test_circle_shape_2d():
	var shape = CircleShape2D.new()
	shape.set_radius(32)
	assert_eq(shape.radius, 32.0, "CircleShape2D radius should be settable")


func test_rectangle_shape_2d_uses_size():
	var shape = RectangleShape2D.new()
	# In Godot 4, RectangleShape2D uses 'size' (full size) not 'extents' (half-size)
	shape.size = Vector2(64, 64)
	assert_eq(shape.size, Vector2(64, 64), "RectangleShape2D should use size property")


func test_file_access_api():
	# Godot 4 uses FileAccess instead of File
	var file = FileAccess.open("res://project.godot", FileAccess.READ)
	assert_not_null(file, "FileAccess.open should work for existing files")
	var content = file.get_as_text()
	assert_true(content.length() > 0, "Should be able to read file contents")
	file.close()


func test_dir_access_api():
	# Godot 4 uses DirAccess instead of Directory
	var dir = DirAccess.open("res://")
	assert_not_null(dir, "DirAccess.open should work")
	assert_true(dir.file_exists("project.godot"), "Should find project.godot")


func test_scene_instantiate():
	# Verify .instantiate() works (not .instance())
	var scene = load("res://crash/Junk.tscn")
	assert_not_null(scene, "Scene should load")
	var instance = scene.instantiate()
	assert_not_null(instance, "instantiate() should work")
	instance.free()


func test_color_constructor():
	# Verify Color constructors work in Godot 4
	var c1 = Color(1.0, 0.5, 0.25, 1.0)
	assert_eq(c1.r, 1.0, "Color r should be 1.0")
	assert_eq(c1.g, 0.5, "Color g should be 0.5")
	assert_almost_eq(c1.b, 0.25, 0.001, "Color b should be 0.25")
	assert_eq(c1.a, 1.0, "Color a should be 1.0")


func test_vector2i():
	# Vector2i is used in Godot 4 TileMap API
	var v = Vector2i(3, 5)
	assert_eq(v.x, 3, "Vector2i x should be 3")
	assert_eq(v.y, 5, "Vector2i y should be 5")


func test_callable():
	# Callable is the Godot 4 way to reference methods
	var callable = Callable(self, "_dummy_method")
	assert_true(callable.is_valid(), "Callable should be valid")


func _dummy_method():
	pass
