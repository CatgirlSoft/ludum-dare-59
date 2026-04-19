extends Control

@onready var timer: Timer = $Total_Timer
@onready var last_input_timer: Timer = $Last_Input_Timer

@onready var curve: Curve_Class = $Curve

var total_score: float = 0.0
var level: int = 1
var can_confirm_score: bool = false

var target_score: float = 90.0
var current_score: float

func _ready() -> void:
	timer.start()

func _input(_event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		last_input_timer.start(2.0)
		can_confirm_score = false

func _process(_delta: float) -> void:
	if can_confirm_score and (target_score <= current_score):

		print(current_score)
		total_score += current_score

		can_confirm_score = false
		current_score = 0
		level += 1

		if level % 10 == 0:
			curve.target = curve.generate_random_combined(2,10)
		else:
			curve.target = curve.generate_random_combined(1,10)
		
		curve.recalculate_player_layers()
		curve._refresh()

func _on_game_start()-> void:
	curve.target = curve.generate_random_combined(1,10)
	curve._refresh()

func _on_timer_timeout()-> void:
	pass


func _on_curve_layer_changed(layer_index: int) -> void:
	pass


func _on_curve_score_changed(new_score: float) -> void:
	current_score = new_score

func _on_last_input_timer_timeout() -> void:
	can_confirm_score = true


#TODO
# Timer
# Timer run out
#
# Score led
# 
# FInish UI 
#
# SOUND
# Button
# static sound
# decoded message clear sound
