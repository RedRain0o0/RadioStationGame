class_name BaseWindow
extends PanelContainer

const focused_bar_color: Color = Color(0.0, 0.0, 0.502, 1.0)
const unfocused_bar_color: Color = Color(0.502, 0.502, 0.502, 1.0)
const focused_text_color: Color = Color(1.0, 1.0, 1.0, 1.0)
const unfocused_text_color: Color = Color(0.753, 0.753, 0.753, 1.0)

@onready var computer_ui: ComputerUI = $"../.."
@onready var focus_bar: ColorRect = $VBoxContainer/FocusBar
@onready var window_title: RichTextLabel = $VBoxContainer/FocusBar/HBoxContainer/WindowTitle

var dragging: bool = false
var mouse_offset: Vector2 = Vector2.ZERO

var is_focused: bool = false

func _gui_input(event: InputEvent) -> void:
	print("Event of type ", typeof(event), " at ", event.position)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("update other")
		for window in computer_ui.windows:
			if window != self:
				window.z_index = 0
				window.is_focused = false
				window.focus_bar.color = unfocused_bar_color
				window.window_title.add_theme_color_override("font_color", unfocused_text_color)
		self.z_index = 1
		is_focused = true
		focus_bar.color = focused_bar_color
		window_title.add_theme_color_override("font_color", focused_text_color)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		print("focus")
		if event.is_pressed():
			dragging = true
			mouse_offset = event.position
			print(event.position)
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		print("drag ", position, " to ", event.relative)
		position = computer_ui.mouse_cursor.position - mouse_offset
		var viewport_size: Vector2 = get_viewport().size
		position.y = clamp(position.y, 0, viewport_size.y + size.y - 30.0)
