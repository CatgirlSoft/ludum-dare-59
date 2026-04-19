extends Control

@onready var game = preload("uid://bp16nh4e1u7rh")

func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(game)
	pass


func _on_option_pressed() -> void:
	$"..".change_menu(1)


func _on_credit_pressed() -> void:
	$"..".change_menu(2)


func _on_quit_pressed() -> void:
	get_tree().quit()
