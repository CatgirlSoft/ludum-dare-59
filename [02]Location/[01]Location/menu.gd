extends Control

@onready var start_menu: Control = $StartMenu
@onready var option: Control = $Option
@onready var credit: Control = $Credit


func change_menu(index: int) -> void:
	match index:
		0:
			start_menu.visible = true
			option.visible = false
			credit.visible = false
		1:
			start_menu.visible = false
			option.visible = true
			credit.visible = false
		2:
			start_menu.visible = false
			option.visible = false
			credit.visible = true
