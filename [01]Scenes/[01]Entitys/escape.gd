extends Node

func _input(event: InputEvent) -> void:
	if OS.get_name() != "Web":
		if Input.is_action_pressed("ui_cancel"):
			get_tree().quit()
