class_name ComputerUI
extends Control


@onready var base_window_scene: Resource = preload("res://Scenes/Templates/BaseWindow.tscn")

@onready var sub_viewport: SubViewport = $".."
@onready var mouse_cursor: Control = $MouseCursor
@export var windows: Array[BaseWindow]
@onready var windows_node: Control = $WindowsNode

func handle_mouse_button_event(passed_event: InputEventMouseButton) -> void:
	var mouse_event = InputEventMouseButton.new()
	mouse_event.button_index = passed_event.button_index
	mouse_event.pressed = passed_event.pressed
	mouse_event.position = mouse_cursor.position
	mouse_event.global_position = mouse_cursor.position
	sub_viewport.push_input(mouse_event)

func handle_mouse_motion_event(passed_event: InputEventMouseMotion) -> void:
	mouse_cursor.position += passed_event.relative
	mouse_cursor.position.x = clamp(mouse_cursor.position.x, 0.0, sub_viewport.size.x - 1.0)
	mouse_cursor.position.y = clamp(mouse_cursor.position.y, 0.0, sub_viewport.size.y - 1.0)
	
	var mouse_event = InputEventMouseMotion.new()
	mouse_event.position = mouse_cursor.position
	mouse_event.global_position = mouse_cursor.position
	sub_viewport.push_input(mouse_event)


func _on_start_button_pressed() -> void:
	var base_window: BaseWindow = base_window_scene.instantiate()
	windows_node.add_child(base_window)
	windows.append(base_window)
