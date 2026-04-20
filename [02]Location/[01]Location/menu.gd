extends Control

@onready var start_menu: Control = $StartMenu
@onready var option: Control = $Option
@onready var credit: Control = $Credit
@onready var quit: Button = $StartMenu/HBoxContainer/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer2/VBoxContainer/Quit

func _ready() -> void:
	if OS.get_name() == "Web":
		quit.visible = false
	else:
		quit.visible = true

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
