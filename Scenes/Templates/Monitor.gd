class_name Monitor
extends StaticBody3D

@onready var interactable: Interactable = $Interactable
@onready var camera_focus_point: Node3D = $"../CameraFocusPoint"
@onready var sub_viewport: SubViewport = $SubViewport
@onready var computer_ui: ComputerUI = $SubViewport/ComputerUi

var is_using: bool = false
var active_player: PlayerController = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.

func toggle_use(interacting_player: PlayerController) -> void:
	sub_viewport.warp_mouse(sub_viewport.size/2)
	is_using = !is_using
	if is_using: active_player = interacting_player
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if is_using else Input.MOUSE_MODE_CAPTURED)
	active_player.can_move = !is_using
	active_player.input_locked = is_using
	active_player.camera_zoomed = is_using
	active_player.player_ui.update_show_ui(!is_using)
	$"../CameraFocusPoint/Camera3D".current = is_using
	if !is_using: active_player = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if !is_using: return
	if event is InputEventKey:
		if Input.is_action_just_pressed("ui_cancel"):
			print("Exit Computer")
			toggle_use(null)
			get_viewport().set_input_as_handled()
		else:
			print("Push event to Sub Viewport")
			sub_viewport.push_input(event)
	#elif event is InputEventMouse:
		#print(event.position)
		#computer_ui.mouse_position = event.position
		#computer_ui.update_cursor_position()
		#sub_viewport.push_input(event)
	elif event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			var mouse_event = InputEventMouseButton.new()
			mouse_event.button_index = event.button_index
			mouse_event.pressed = event.pressed
			mouse_event.position = computer_ui.mouse_position
			mouse_event.global_position = computer_ui.mouse_position
			print("Push mouse event to Sub Viewport with position " + str(mouse_event.position) + " (" + str(mouse_event.global_position) + ")")
			sub_viewport.push_input(mouse_event)
	elif event is InputEventMouseMotion:
		#print("Mouse position was " + str(computer_ui.mouse_position))
		computer_ui.mouse_position += event.relative
		computer_ui.mouse_position.x = clamp(computer_ui.mouse_position.x, 0.0, sub_viewport.size.x - 1.0)
		computer_ui.mouse_position.y = clamp(computer_ui.mouse_position.y, 0.0, sub_viewport.size.y - 1.0)
		#sub_viewport.push_input(event)
		computer_ui.update_cursor_position(event)
		#print("Mouse position is now " + str(computer_ui.mouse_position))
		#print("Mouse was moved by " + str(event.relative))

func interact_monitor() -> void:
	print("Interacted")
	toggle_use(interactable.last_interacted_player)
