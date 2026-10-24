extends Camera3D

func _process(delta: float) -> void:
	look_at(GameManager.player_reference.position + GameManager.player_reference.get_head_height())
