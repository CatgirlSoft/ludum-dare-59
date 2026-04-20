extends Control

@onready var timer: Timer = $Total_Timer
@onready var last_input_timer: Timer = $Last_Input_Timer

@onready var timer_label: Label = %Timer

@onready var curve: Curve_Class = $Curve
@onready var Led: TextureRect = %LED

var total_score: float = 0.0
var level: int = 0
var can_confirm_score: bool = false

var target_score: float = 85.0
var current_score: float


func _input(_event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		last_input_timer.start(2.0)
		can_confirm_score = false

func _process(_delta: float) -> void:
	if timer.time_left >= 0:
		timer_label.text = str(timer.time_left).left(2) + ":" + str(timer.time_left).left(5).right(2)
		
		if can_confirm_score and (target_score <= current_score):

			total_score += current_score
			if current_score > 90:
				timer.start(timer.time_left + (20))
			else:
				timer.start(timer.time_left + (12))
				

			can_confirm_score = false
			current_score = 0
			level += 1

			if level % 10 == 0:
				curve.target = curve.generate_random_combined(3,10)
			else:
				curve.target = curve.generate_random_combined(2,10)
			
			curve.recalculate_player_layers()
			curve._refresh()

func _on_game_start()-> void:
	curve.target = curve.generate_random_combined(1,10)
	curve._refresh()

func _on_timer_timeout()-> void:
	$Panel.visible = true
	if level >= 10:
		$Panel/VBoxContainer/Mission_Succed.visible = true
		$Panel/VBoxContainer/good_job.visible = true
	else:
		$Panel/VBoxContainer/Mission_fail.visible = true
		$Panel/VBoxContainer/bad_job.visible = true
	if total_score == 0:
		$Panel/VBoxContainer/score.text = "average accuracy: 00.00%"
	else:
		$Panel/VBoxContainer/score.text = "average accuracy: " + str(total_score / level).pad_decimals(2) + "%"
	$Panel/VBoxContainer/curve_number.text = "number of curves: " + str(level) + "/10"
	
func _on_curve_layer_changed(layer_index: int) -> void:
	pass


func _on_curve_score_changed(new_score: float) -> void:
	if timer:
		if timer.time_left >= 0:
			current_score = new_score
			if Led:
				if new_score >= target_score:
					Led.modulate = Color(0.0, 2.0, 0.0, 1.0)
				else:
					Led.modulate = Color("666666ff")

func _on_last_input_timer_timeout() -> void:
	can_confirm_score = true
	


#TODO
# Timer run out
#
#
# SOUND
# Button
# static sound
# decoded message clear sound
