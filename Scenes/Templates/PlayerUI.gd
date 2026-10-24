class_name PlayerUI
extends Control

@onready var fps_label: Label = $MarginContainer/FPSLabel
@onready var offset_label: Label = $MarginContainer/HBoxContainer/OffsetLabel
@onready var interactable_label: Label = $MarginContainer/HBoxContainer/InteractableLabel
@onready var crosshair: Panel = $MarginContainer/Crosshair

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

func update_label(name: String) -> void:
	offset_label.text = name
	interactable_label.text = name

func update_show_ui(show: bool) -> void:
	$MarginContainer/HBoxContainer.visible = show
	crosshair.visible = show
	pass
