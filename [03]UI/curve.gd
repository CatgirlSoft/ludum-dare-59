extends Control

@onready var curve: Control = $"."
@onready var option_button: OptionButton = $OptionButton

@onready var percentage_label: Label = $Label
@onready var layer_label: Label = $Label2
@onready var combine_op_button: Button = $Button3

@export_group("Node_reference")
@export var amplitude_slider: VSlider
@export var phase_slider: HSlider
@export var frequency_slider: Knob

@export var previous_layer_button: Button
@export var next_layer_button: Button

@export var previous_wave_type: TextureButton
@export var next_wave_type: TextureButton

@export var curve_addition_type: TextureButton

@export var right_screen: Control
@export var left_screen: Control

@export_group("Value")
@export var number_of_layers: int = 2

@export var number_of_samples: int = 10

@export var amplitude: float = 100.0
@export var frequency: float = 0
@export var phase: float = 0
@export var wave_type = WaveType.SINE

var target_amplitude: float
var target_frequency: float
var target_phase: float
var target_wave_type: WaveType

var x_size = 5
var step = 0.1

var samples = []
var target = []

var target_layers = []
var target_ops = []

var player_layers = []
var player_ops = []
var current_layer_index: int = 0

signal score_changed(new_score: float)
signal layer_changed(layer_index: int)

enum WaveType {
	SINE,
	SQUARE,
	SAW,
	TRIANGLE
}
enum CombineOp {
	ADD,
	MULTIPLY,
	MAX,
	MIN
}

func _ready() -> void:
	if amplitude_slider: amplitude_slider.connect("value_changed",_on_amplitude_value_changed)
	if phase_slider: phase_slider.connect("value_changed",_on_phase_value_changed)
	if frequency_slider: frequency_slider.connect("value_changed",_on_frequency_value_changed)
	
	if previous_layer_button: previous_layer_button.connect("pressed",_on_previous_layer)
	if next_layer_button: next_layer_button.connect("pressed",_on_next_layer)
	
	if previous_wave_type: previous_wave_type.connect("pressed",_on_previous_curve_pressed)
	if next_wave_type: next_wave_type.connect("pressed",_on_next_curve_pressed)
	
	if curve_addition_type: curve_addition_type.connect("pressed",_on_toggle_op)

	target = generate_random_combined(number_of_layers, number_of_samples)

	player_layers = []
	player_ops = []
	for i in range(target_layers.size()):
		player_layers.append(_first_layer())
	for i in range(target_layers.size() - 1):
		player_ops.append(CombineOp.ADD)
	current_layer_index = 0
	_update_ui()

func sine_wave(x: float) -> float:
	return cos(x)

func square_wave(x: float) -> float:
	return sign(sine_wave(x))

func saw_wave(x: float) -> float:
	return 2.0 * (x / TAU - floor(0.5 + x / TAU))

func triangle_wave(x: float) -> float:
	return abs(saw_wave(x)) * 2.0 - 1.0

func wave(x: float, type: WaveType = WaveType.SINE) -> float:
	match type:
		WaveType.SINE:
			return sine_wave(x)
		WaveType.SQUARE:
			return square_wave(x)
		WaveType.SAW:
			return saw_wave(x)
		WaveType.TRIANGLE:
			return triangle_wave(x)
	return 0.0

func _draw() -> void:
	var left_screen_center = left_screen.global_position + left_screen.size / 2
	var left_screen_width = left_screen.size.x
	var right_screen_center = right_screen.global_position + right_screen.size / 2
	var right_screen_width = right_screen.size.x

	var samples_count = samples.size()
	var target_count = target.size()
	for i in range(samples_count - 1):
		var x0 = left_screen_center.x + (float(i) / (samples_count - 1) - 0.5) * left_screen_width
		var x1 = left_screen_center.x + (float(i + 1) / (samples_count - 1) - 0.5) * left_screen_width
		draw_line(
			Vector2(x0, left_screen_center.y + samples[i]),
			Vector2(x1, left_screen_center.y + samples[i + 1]),
			Color.ALICE_BLUE, 3, true)
	for i in range(target_count - 1):
		var x0 = right_screen_center.x + (float(i) / (target_count - 1) - 0.5) * right_screen_width
		var x1 = right_screen_center.x + (float(i + 1) / (target_count - 1) - 0.5) * right_screen_width
		draw_line(
			Vector2(x0, right_screen_center.y + target[i]),
			Vector2(x1, right_screen_center.y + target[i + 1]),
			Color.ALICE_BLUE, 3, true)

func compare(a: Array, b: Array) -> float:
	var min_size = mini(a.size(), b.size())
	var sum = 0.0
	for i in  range(min_size):
		var diff = a[i] - b[i]
		sum += diff * diff
	return sum / min_size

func combine(a: Array, b: Array, op: CombineOp) -> Array:
	var result = []
	@warning_ignore("shadowed_variable_base_class")
	var size = mini(a.size(), b.size())
	for i in range(size):
		match op:
			CombineOp.ADD: result.append(a[i] + b[i])
			CombineOp.MULTIPLY: result.append(a[i] * b[i] * 0.01)
			CombineOp.MAX: result.append(maxf(a[i], b[i]))
			CombineOp.MIN: result.append(minf(a[i], b[i]))
	return result

func generate_layer(layer: Dictionary, number_samples: int) -> Array:
	var inner = []
	var x = 0.0
	while x < number_samples:
		var time = layer.frequency * x
		var value = layer.amplitude * wave(time - layer.phase, layer.wave_type)
		inner.append(value)
		x += step
	return inner

func generate_random_combined(num_layers: int, number_samples: int) -> Array:
	target_layers = []
	target_ops = []
	
	for i in range(num_layers):
		var layer = {
			"amplitude": randf_range(min(amplitude_slider.min_value, 2.0), min(amplitude_slider.max_value, 100.0)),
			"frequency": randf_range(frequency_slider.min_value, frequency_slider.max_value),
			"phase":     randf_range(phase_slider.min_value, phase_slider.max_value),
			"wave_type": WaveType.values()[randi() % WaveType.size()]
		}
		target_layers.append(layer)
		
		if i > 0:
			var prev_type = target_layers[i - 1].wave_type
			var op = _pick_op(prev_type, layer.wave_type)
			target_ops.append(op)
	return _evaluate_layers(target_layers, target_ops, number_samples)

func _pick_op(type_a: WaveType, type_b: WaveType) -> CombineOp:
	var all_ops = CombineOp.values()
	if type_a == type_b:
		all_ops.erase(CombineOp.MULTIPLY)
	return all_ops[randi() % all_ops.size()]

func _evaluate_layers(layers: Array, ops: Array, number_samples: int) -> Array:
	if layers.is_empty():
		return []
	var result = generate_layer(layers[0], number_samples)
	for i in range(ops.size()):
		var next_layer = generate_layer(layers[i + 1], number_samples)
		result = combine(result, next_layer, ops[i])
	return result

func _first_layer() -> Dictionary:
	return {
		"amplitude": randf_range(30.0, 70.0),
		"frequency": randf_range(0.3, 1.7),
		"phase":     randf_range(0.5, 1.5),
		"wave_type": WaveType.SINE
	}

func generate_random(number_samples: int) -> Array:
	var inner = []

	target_amplitude = randf_range(0.0, 100.0)
	target_frequency = randf_range(0.0, 2.0)
	target_phase = randf_range(0.0, 10.0)

	var rand_type = WaveType.keys()[randi() % WaveType.size()]
	target_wave_type = WaveType[rand_type]

	var x = 0.0
	while x < number_samples:
		var time = target_frequency * x
		var value = target_amplitude * wave(time - target_phase, target_wave_type)
		inner.append(value)
		x += step
	return inner

func _update_ui() -> void:
	var layer = player_layers[current_layer_index]
	amplitude_slider.value = layer.amplitude
	frequency_slider.value = layer.frequency
	phase_slider.value = layer.phase
	_update_combine_op_button()

func _update_combine_op_button() -> void:
	if current_layer_index < player_ops.size():
		combine_op_button.text = "OP:" + CombineOp.find_key(player_ops[current_layer_index])
		combine_op_button.visible = true
	else:
		combine_op_button.visible = false

func _save_from_ui() -> void:
	player_layers[current_layer_index] = {
		"amplitude": amplitude_slider.value,
		"frequency": frequency_slider.value,
		"phase":     phase_slider.value,
		"wave_type": player_layers[current_layer_index].wave_type
	}

func score() -> float:
	var mse = compare(samples, target)
	var percent = clampf(100.0 * (1.0 - mse / 10000.0), 0.0, 100.0)
	percentage_label.text = str(percent).pad_decimals(2) + "%"
	return percent

func _refresh() -> void:
	samples = _evaluate_layers(player_layers, player_ops, number_of_samples)
	var new_score = score()
	score_changed.emit(new_score)
	queue_redraw()

func _on_amplitude_value_changed(value: float) -> void:
	player_layers[current_layer_index].amplitude = value
	_refresh()

func _on_phase_value_changed(value: float) -> void:
	player_layers[current_layer_index].phase = value
	_refresh()

func _on_frequency_value_changed(value: float) -> void:
	if player_layers:
		player_layers[current_layer_index].frequency = value
		_refresh()

func _on_option_button_item_selected(index: int) -> void:
	var id = option_button.get_item_id(index)
	var key = WaveType.find_key(id)
	player_layers[current_layer_index].wave_type = WaveType[key]
	_refresh()

func _on_previous_curve_pressed():
	var types = WaveType.values()
	var current = player_layers[current_layer_index].wave_type
	var index = types.find(current)
	player_layers[current_layer_index].wave_type = types[(index - 1 + types.size()) % types.size()]
	_refresh()

func _on_next_curve_pressed():
	var types = WaveType.values()
	var current = player_layers[current_layer_index].wave_type
	var index = types.find(current)
	player_layers[current_layer_index].wave_type = types[(index + 1) % types.size()]
	_refresh()
	
func _on_previous_layer() -> void:
	_save_from_ui()
	current_layer_index = (current_layer_index - 1 + player_layers.size()) % player_layers.size()
	_update_ui()
	layer_changed.emit(current_layer_index)
	_refresh()

func _on_next_layer() -> void:
	_save_from_ui()
	current_layer_index = (current_layer_index + 1) % player_layers.size()
	_update_ui()
	layer_changed.emit(current_layer_index)
	_refresh()

func _on_toggle_op() -> void:
	if current_layer_index < player_ops.size():
		var all_ops = CombineOp.values()
		var next = (player_ops[current_layer_index] + 1) % all_ops.size()
		player_ops[current_layer_index] = next
		_update_combine_op_button()
		_refresh()
