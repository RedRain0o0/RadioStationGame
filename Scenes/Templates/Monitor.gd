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
	is_using = !is_using
	if is_using: active_player = interacting_player
	if active_player:
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
			toggle_use(null)
			get_viewport().set_input_as_handled()
		else:
			sub_viewport.push_input(event)
	elif event is InputEventMouseButton:
		computer_ui.handle_mouse_button_event(event)
	elif event is InputEventMouseMotion:
		computer_ui.handle_mouse_motion_event(event)

func interact_monitor() -> void:
	print("Interacted")
	toggle_use(interactable.last_interacted_player)
