extends Control


func _on_play_pressed() -> void:
	#get_tree().change_scene_to_file()
	pass


func _on_option_pressed() -> void:
	$"..".change_menu(1)


func _on_credit_pressed() -> void:
	$"..".change_menu(2)


func _on_quit_pressed() -> void:
	get_tree().quit()
