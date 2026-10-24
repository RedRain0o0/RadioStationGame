class_name ComputerUI
extends Control

@onready var sub_viewport: SubViewport = $".."
@onready var mouse_cursor: Control = $MouseCursor
var mouse_position: Vector2 = Vector2.ZERO


func update_cursor_position(event: InputEventMouseMotion) -> void:
	sub_viewport.warp_mouse(mouse_position)
	mouse_cursor.position = mouse_position
	print("Mouse position is now " + str(mouse_position))
	#mouse_position
