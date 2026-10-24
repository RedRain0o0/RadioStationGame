extends AnimatableBody3D

@export var open: bool = false:
	set(v):
		if v != open:
			open = v
			update_door()

func update_door() -> void:
	if open:
		$AnimationPlayer.play("open")
	else:
		$AnimationPlayer.play_backwards("open")
	$AnimationPlayer.set_active(true)

func toggle_open() -> void:
	open = !open
