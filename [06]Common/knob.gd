extends Control

signal	value_changed(new_value: float)

@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var step: float = 0.0
@export var sensitivity: float = 0.5

@export var min_angle_deg: float = -135.0
@export var max_angle_deg: float = 135.0

var _value: float = 0.0
var _dragging: bool = false
var _previous_angle: float = 0.0
var _cumulated_deg: float = 0.0
var _start_drag_value: float = 0.0

var value: float:
	get: return _value
	set(v): _set_value(v)

func _ready() -> void:
	_update_rotation()

func _update_rotation() -> void:
	var t := inverse_lerp(min_value, max_value, _value)
	rotation_degrees = lerpf(min_angle_deg, max_angle_deg, t)

func _set_value(v: float) -> void:
	var clamped := clampf(v, min_value, max_value)
	if step > 0.0:
		clamped = roundf(clamped / step) * step
	if is_equal_approx(clamped, _value):
		return
	_value = clamped
	_update_rotation()
	value_changed.emit(_value)

func _get_angle_from_center(mouse_pos: Vector2) -> float:
	var center := global_position + pivot_offset
	var offset := mouse_pos - center
	return rad_to_deg(atan2(offset.x, -offset.y))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_previous_angle = _get_angle_from_center(event.global_position)
				_cumulated_deg = 0.0
				_start_drag_value = _value
			else:
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		var current_angle := _get_angle_from_center(event.global_position)
		
		var delta := current_angle - _previous_angle
		
		if delta > 180.0:
			delta -= 360.0
		elif delta < -180.0:
			delta += 360.0
		
		_cumulated_deg += delta
		_previous_angle = current_angle
		
		var sweep := max_angle_deg - min_angle_deg
		var delta_value := _cumulated_deg / sweep * (max_value - min_value)
		value = _start_drag_value + delta_value
		
