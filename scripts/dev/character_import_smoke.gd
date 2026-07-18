extends SceneTree
## godot --path . --headless -s res://scripts/dev/character_import_smoke.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	print("=== CHARACTER IMPORT SMOKE ===")
	for path in [
		"res://resources/sprite_frames/characters/guildmaster.tres",
		"res://resources/sprite_frames/characters/pronyra.tres",
		"res://assets/characters/guildmaster/portraits/neutral.png",
		"res://assets/characters/pronyra/portraits/neutral.png",
		"res://scenes/characters/guildmaster.tscn",
	]:
		assert(ResourceLoader.exists(path), "Missing %s" % path)
		print("OK ", path)

	var gm: SpriteFrames = load("res://resources/sprite_frames/characters/guildmaster.tres")
	var thief: SpriteFrames = load("res://resources/sprite_frames/characters/pronyra.tres")
	for anim in ["idle", "run", "walk", "talk", "enter"]:
		assert(gm.has_animation(anim), "GM missing %s" % anim)
		assert(thief.has_animation(anim), "Pronyra missing %s" % anim)
		assert(gm.get_frame_count(anim) > 0)
	assert(gm.get_frame_count("idle") == 8)
	assert(gm.get_frame_count("run") == 8)
	print("Animations OK")

	var err := change_scene_to_file("res://scenes/characters/guildmaster.tscn")
	assert(err == OK)
	await process_frame
	await process_frame
	print("Guildmaster scene OK")

	print("=== CHARACTER IMPORT SMOKE PASS ===")
	quit(0)
