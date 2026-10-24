class_name Interactable
extends Node

@export var interact_name: String

var last_interacted_player: PlayerController = null

signal interacted()

func interact_with(interacting_player: PlayerController) -> void:
	last_interacted_player = interacting_player
	interacted.emit()
