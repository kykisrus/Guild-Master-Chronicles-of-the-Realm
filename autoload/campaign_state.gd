extends Node
## Stage 3 campaign data (separate from legacy GameState hero systems).

const SAVE_VERSION := 1

var guildmaster: Dictionary = {}
var guild: Dictionary = {}
var world: Dictionary = {"scene": "guild_hub", "water_edge": true}
var time: Dictionary = {"day": 1, "year": 1}
var flags: Dictionary = {
	"intro_completed": false,
	"thief_left": false,
	"treasury_checked": false,
	"administrator_hired": false,
}

# Staging fields during intro before save
var pending_gm: Dictionary = {}
var pending_guild_name: String = ""
var pending_palette: String = "blue"


func reset() -> void:
	guildmaster = {}
	guild = {}
	world = {"scene": "guild_hub", "water_edge": true}
	time = {"day": 1, "year": 1}
	flags = {
		"intro_completed": false,
		"thief_left": false,
		"treasury_checked": false,
		"administrator_hired": false,
	}
	pending_gm = {}
	pending_guild_name = ""
	pending_palette = "blue"


func set_pending_guildmaster(data: Dictionary) -> void:
	pending_gm = data.duplicate(true)


func set_pending_guild(guild_name: String, palette: String) -> void:
	pending_guild_name = guild_name.strip_edges()
	pending_palette = palette


func found_guild() -> void:
	guildmaster = pending_gm.duplicate(true)
	if not guildmaster.has("gender"):
		guildmaster["gender"] = "male"
	guild = {
		"name": pending_guild_name,
		"palette": pending_palette,
		"level": 1,
		"hall_id": "barracks",
		"founded": true,
	}
	flags["intro_completed"] = true
	flags["thief_left"] = true
	time = {"day": 1, "year": 1}
	world = {"scene": "guild_hub", "water_edge": true}


func to_save_dict() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"created_at": Time.get_datetime_string_from_system(),
		"intro_completed": bool(flags.get("intro_completed", false)),
		"guildmaster": guildmaster.duplicate(true),
		"guild": guild.duplicate(true),
		"world": world.duplicate(true),
		"time": time.duplicate(true),
		"flags": flags.duplicate(true),
		# Convenience for load menu labels
		"guild_name": str(guild.get("name", "")),
		"saved_at": Time.get_datetime_string_from_system(),
	}


func load_from_dict(data: Dictionary) -> void:
	guildmaster = data.get("guildmaster", {}).duplicate(true) if typeof(data.get("guildmaster", {})) == TYPE_DICTIONARY else {}
	guild = data.get("guild", {}).duplicate(true) if typeof(data.get("guild", {})) == TYPE_DICTIONARY else {}
	world = data.get("world", {"scene": "guild_hub", "water_edge": true}).duplicate(true) if typeof(data.get("world", {})) == TYPE_DICTIONARY else {"scene": "guild_hub", "water_edge": true}
	time = data.get("time", {"day": 1, "year": 1}).duplicate(true) if typeof(data.get("time", {})) == TYPE_DICTIONARY else {"day": 1, "year": 1}
	flags = data.get("flags", {}).duplicate(true) if typeof(data.get("flags", {})) == TYPE_DICTIONARY else {}
	if data.has("intro_completed"):
		flags["intro_completed"] = bool(data["intro_completed"])


func guild_display_name() -> String:
	return str(guild.get("name", "Гильдия"))


func guild_palette() -> String:
	return str(guild.get("palette", "blue")).to_lower()
