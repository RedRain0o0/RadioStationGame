extends Node

var config: ConfigFile = ConfigFile.new()
const CONFIG_PATH = "user://config.ini"

var input_actions = {
	"move_forward": ["W", "Move Forwards"],
	"move_backward": ["S", "Move Backwards"],
	"move_left": ["A", "Move Left"],
	"move_right": ["D", "Move Right"],
	"jump": ["space", "Jump"],
	"crouch": ["ctrl", "Crouch"]
}

func _ready() -> void:
	if !FileAccess.file_exists(CONFIG_PATH):
		for action in input_actions:
			config.set_value("keybinds", action, input_actions[action][0])
		
		config.set_value("audio", "master_volume", 1.0)
		
		config.set_value("graphics", "fov", 90.0)
		
		config.set_value("accessibility", "easier_typing", false)
		
		config.save(CONFIG_PATH)
	else:
		config.load(CONFIG_PATH)

func save_keybind(action: StringName, event: InputEvent) -> void:
	var key_name: String
	if event is InputEventKey:
		key_name = OS.get_keycode_string(event.physical_keycode)
	elif event is InputEventMouseButton:
		key_name = "mouse_" + str(event.button_index)
	
	config.set_value("keybinds", action, key_name)
	config.save(CONFIG_PATH)

func load_keybinds() -> Dictionary:
	var keybinds: Dictionary = {}
	var keys: PackedStringArray = config.get_section_keys("keybinds")
	for key in keys:
		var input_event
		var event_str: String = config.get_value("keybinds", key)
		if event_str.contains("mouse_"):
			input_event = InputEventMouseButton.new()
			input_event.button_index = int(event_str.split("_")[1])
		else:
			input_event = InputEventKey.new()
			input_event.keycode = OS.find_keycode_from_string(event_str)
		
		keybinds[key] = input_event
	return keybinds

func save_graphics_setting(key: String, value) -> void:
	config.set_value("graphics", key, value)
	config.save(CONFIG_PATH)

func load_graphics_settings() -> Dictionary:
	var graphics_settings: Dictionary = {}
	for key in config.get_section_keys("graphics"):
		graphics_settings[key] = config.get_value("graphics", key)
	return graphics_settings

func save_audio_setting(key: String, value) -> void:
	config.set_value("audio", key, value)
	config.save(CONFIG_PATH)

func load_audio_settings() -> Dictionary:
	var audio_settings: Dictionary = {}
	for key in config.get_section_keys("audio"):
		audio_settings[key] = config.get_value("audio", key)
	return audio_settings
