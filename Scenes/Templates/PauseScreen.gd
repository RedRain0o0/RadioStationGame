extends Control

@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %Settings
@onready var unstuck_button: Button = %Unstuck
@onready var quit_button: Button = %QuitButton
@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var settings: Control = $CenterContainer/Settings
@onready var version: Label = $Version
@onready var player: CharacterBody3D = $".."
var is_paused: bool = false

func _ready() -> void:
	version.text = ProjectSettings.get_setting("application/config/version")
	resume_button.pressed.connect(unpause)
	settings_button.pressed.connect(open_settings)
	unstuck_button.pressed.connect(unstuck)
	quit_button.pressed.connect(get_tree().quit)

func unpause() -> void:
	animator.play("Unpause")
	get_tree().paused = false
	is_paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func pause() -> void:
	animator.play("Pause")
	get_tree().paused = true
	is_paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func open_settings() -> void:
	panel_container.visible = false
	settings.visible = true

func unstuck() -> void:
	player.unstuck()
	unpause()

func close_settings() -> void:
	panel_container.visible = true
	settings.visible = false
