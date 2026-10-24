extends Control

@onready var input_button_scene: Resource = preload("res://Scenes/Templates/InputButton.tscn")
@onready var action_list: VBoxContainer = $Background/TabContainer/Bindings/MarginContainer/ActionList
var is_remapping: bool = false
var action_to_remap = null
var remapping_button = null

@onready var back_button: Button = $Background/BackButton
@onready var parent: Control = $"../.."
@onready var fov_edit: LineEdit = $Background/TabContainer/Settings/MarginContainer/VBoxContainer/AccessibilityContainer/VBoxContainer/FOVContainer/HBoxContainer/FOVEdit
@onready var fov_slider: HSlider = $Background/TabContainer/Settings/MarginContainer/VBoxContainer/AccessibilityContainer/VBoxContainer/FOVContainer/FOVSlider
var updated_fov: bool = false
var first_update: bool = true

func _ready() -> void:
	back_button.pressed.connect(parent.close_settings)
	fov_slider.value = ConfigHandler.load_graphics_settings().get("fov")
	first_update = false
	var keybinds: Dictionary = ConfigHandler.load_keybinds()
	for keybind in keybinds.keys():
		InputMap.action_erase_events(keybind)
		InputMap.action_add_event(keybind, keybinds[keybind])
	_create_action_list()

func _create_action_list() -> void:
	for item in action_list.get_children():
		item.queue_free()
	
	for action in ConfigHandler.input_actions:
		var action_button: Button = input_button_scene.instantiate()
		var action_label: Label = action_button.find_child("ActionLabel")
		var input_label: Label = action_button.find_child("InputLabel")
		
		action_label.text = ConfigHandler.input_actions[action][1]
		
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			input_label.text = events[0].as_text().trim_suffix(" - Physical")
		else:
			input_label.text = ""
		
		action_list.add_child(action_button)
		action_button.pressed.connect(on_action_button_pressed.bind(action_button, action))

func on_action_button_pressed(button: Button, action) -> void:
	if !is_remapping:
		is_remapping = true
		action_to_remap = action
		remapping_button = button
		button.find_child("InputLabel").text = "Press key to bind..."

func _input(event: InputEvent) -> void:
	if is_remapping:
		if (event is InputEventKey || (event is InputEventMouseButton && event.pressed)):
			InputMap.action_erase_events(action_to_remap)
			if !event.is_action_pressed("ui_cancel"):
				InputMap.action_add_event(action_to_remap, event)
				ConfigHandler.save_keybind(action_to_remap, event)
			update_action_list(remapping_button, event)
			
			is_remapping = false
			action_to_remap = null
			remapping_button = null
			
			accept_event()

func update_action_list(button: Button, event) -> void:
	if event.is_action_pressed("ui_cancel"):
		button.find_child("InputLabel").text = "Unbound"
	else:
		button.find_child("InputLabel").text = event.as_text().trim_suffix(" - Physical")

func _on_master_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, value)

func _on_music_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, value)


func _on_misc_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, value)

func update_fov(value: float) -> void:
	updated_fov = true
	if first_update: return
	ConfigHandler.save_graphics_setting("fov", value)
	GameManager.player_reference.camera_fov = value
	GameManager.player_reference.update_camera_fov()

func _on_fov_slider_value_changed(value: float) -> void:
	if updated_fov:
		updated_fov = false
		return
	
	fov_edit.text = str(value)
	update_fov(value)

func _on_fov_edit_text_submitted(new_text: String) -> void:
	if updated_fov:
		updated_fov = false
		return
	
	var value: float = clampf(new_text.to_float(), 70.0, 110.0)
	fov_slider.value = value
	update_fov(value)
