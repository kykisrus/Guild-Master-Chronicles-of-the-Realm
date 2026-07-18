extends SceneTree
## godot --path . --headless -s res://scripts/dev/asset_library_smoke.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	print("=== ASSET LIBRARY SMOKE ===")
	var checks := [
		"res://resources/sprite_frames/tiny_swords/unit_warrior_blue.tres",
		"res://resources/sprite_frames/tiny_swords/unit_archer_red.tres",
		"res://resources/sprite_frames/tiny_swords/unit_lancer_yellow.tres",
		"res://resources/sprite_frames/tiny_swords/unit_monk_purple.tres",
		"res://resources/sprite_frames/tiny_swords/unit_pawn_blue.tres",
		"res://resources/sprite_frames/tiny_neighbours/npc_01.tres",
		"res://resources/sprite_frames/tiny_neighbours/npc_15.tres",
		"res://resources/sprite_frames/tiny_neighbours/emotion_happy.tres",
		"res://resources/sprite_frames/kings_and_pigs/human_king.tres",
		"res://resources/sprite_frames/kings_and_pigs/door.tres",
		"res://resources/tilesets/tiny_swords_terrain.tres",
		"res://resources/tilesets/kings_and_pigs_terrain.tres",
		"res://resources/tilesets/kings_and_pigs_decorations.tres",
		"res://scenes/dev/asset_gallery.tscn",
		"res://scenes/assets/tiny_neighbours/npc_emotion.tscn",
		"res://scenes/assets/kings_and_pigs/basic_door.tscn",
		"res://resources/asset_catalog/tiny_assets.json",
	]
	for path in checks:
		assert(ResourceLoader.exists(path), "Missing %s" % path)
		var res: Resource = load(path)
		assert(res != null, "Load failed %s" % path)
		print("OK ", path)

	var warrior: SpriteFrames = load("res://resources/sprite_frames/tiny_swords/unit_warrior_blue.tres")
	assert(warrior.has_animation(&"idle"), "warrior idle missing")
	assert(warrior.has_animation(&"run"), "warrior run missing")
	assert(warrior.get_frame_count(&"idle") >= 2, "warrior idle frames")

	var king: SpriteFrames = load("res://resources/sprite_frames/kings_and_pigs/human_king.tres")
	for anim in [&"idle", &"run", &"attack", &"dead", &"door_in", &"door_out"]:
		assert(king.has_animation(anim), "king missing %s" % anim)

	var door_scene: PackedScene = load("res://scenes/assets/kings_and_pigs/basic_door.tscn")
	var door: Node = door_scene.instantiate()
	root.add_child(door)
	await process_frame
	assert(door.has_method("open_door"))
	door.call("open_door")
	await process_frame
	door.queue_free()

	var emo_scene: PackedScene = load("res://scenes/assets/tiny_neighbours/npc_emotion.tscn")
	var emo: Node = emo_scene.instantiate()
	root.add_child(emo)
	await process_frame
	emo.call("play_emotion", &"happy")
	await process_frame
	emo.call("stop_emotion")
	emo.queue_free()

	# Stage 1 menu still loads
	var err := change_scene_to_file("res://scenes/menu/main_menu.tscn")
	assert(err == OK)
	await process_frame
	print("=== ASSET LIBRARY SMOKE PASS ===")
	quit(0)
