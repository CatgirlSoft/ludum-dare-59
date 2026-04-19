extends Control

@onready var curve: Control = $"."
@onready var option_button: OptionButton = $OptionButton

@onready var amplitude_slider: VSlider = $Amplitude
@onready var phase_slider: HSlider = $Phase
@onready var frequency_slider: HSlider = $Frequency
@onready var percentage_label: Label = $Label
@onready var layer_label: Label = $Label2
@onready var combine_op_button: Button = $Button3

@export var number_of_layers: int = 2

@export var target_offset_x: float = 0.0
@export var target_offset_y: float = 0.0
@export var player_offset_x: float = 100.0
@export var player_offset_y: float = 0.0

@export var number_of_samples: int = 10

@export var amplitude: float = 100.0
@export var frequency: float = 0
@export var phase: float = 0
@export var wave_type = WaveType.SINE

var target_amplitude: float
var target_frequency: float
var target_phase: float
var target_wave_type: WaveType

@export var x_size = 5
@export var step = 0.1

var samples = []
var target = []

var target_layers = []
var target_ops = []

var player_layers = []
var player_ops = []
var current_layer_index: int = 0

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
	for en in WaveType.keys():
		option_button.add_item(en, WaveType[en])
	option_button.select(0)

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
	for i in range(samples.size() - 1):
		draw_line(
			Vector2((x_size * i) - (x_size * player_offset_x), samples[i] + player_offset_y),
			Vector2((x_size * (i + 1) - (x_size * player_offset_x)), samples[i + 1] + player_offset_y),
			Color.ALICE_BLUE, 3, true
		)
	for i in range(target.size() - 1):
		draw_line(
			Vector2(x_size * i - (x_size * target_offset_x), target[i] + target_offset_y),
			Vector2(x_size * (i + 1) - (x_size * target_offset_x), target[i + 1] + target_offset_y),
			Color.ALICE_BLUE, 3, true
		)

func compare(a: Array, b: Array) -> float:
	var min_size = mini(a.size(), b.size())
	var sum = 0.0
	for i in  range(min_size):
		var diff = a[i] - b[i]
		sum += diff * diff
	return sum / min_size

func generate(number_samples: int) -> Array:
	var inner = []

	var x = 0.0
	while x < number_samples:
		var time = frequency * x
		var value = amplitude * wave(time - phase, wave_type)
		inner.append(value)
		x += step
	return inner

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
			"amplitude": randf_range(10.0, 100.0),
			"frequency": randf_range(0.1, 2.0),
			"phase":     randf_range(0.0, 10.0),
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
		"phase": randf_range(0.5, 1.5),
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
	for i in range(option_button.item_count):
		if option_button.get_item_id(i) == layer.wave_type:
			option_button.select(i)
			break
	layer_label.text = "Layer %d / %d" % [current_layer_index + 1, player_layers.size()]
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
		"phase": phase_slider.value,
		"wave_type": WaveType[WaveType.find_key(option_button.get_item_id(option_button.selected))]
	}

#func score() -> float:
	#var wave_score = 0.0
	#if wave_type == target_wave_type:
		#wave_score = 40.0
	#var amplitude_score = 20.0 * _proximity(amplitude, target_amplitude, 100.0)
	#var frequency_score = 30.0 * _proximity(frequency, target_frequency, 2.0)
	#var phase_score = 10.0 * _proximity(phase, target_phase, 10.0)
	#var percentage = wave_score + amplitude_score + frequency_score + phase_score
	#percentage_label.text = str(percentage).pad_decimals(2) + "%"
	#return percentage

func score() -> float:
	var mse = compare(samples, target)
	var percent = clampf(100.0 * (1.0 - mse / 10000.0), 0.0, 100.0)
	percentage_label.text = str(percent).pad_decimals(2) + "%"
	return percent


@warning_ignore("shadowed_variable")
func _proximity(value: float, target: float, max_range: float) -> float:
	var tolerance = max_range * 0.1
	var diff = abs(value - target)
	return clampf(1.0 - (diff / tolerance), 0.0, 1.0)

func _refresh() -> void:
	samples = _evaluate_layers(player_layers, player_ops, number_of_samples)
	score()
	print(score())
	queue_redraw()

func _on_amplitude_value_changed(value: float) -> void:
	player_layers[current_layer_index].amplitude = value
	_refresh()

func _on_phase_value_changed(value: float) -> void:
	player_layers[current_layer_index].phase = value
	_refresh()

func _on_frequency_value_changed(value: float) -> void:
	player_layers[current_layer_index].frequency = value
	_refresh()

func _on_option_button_item_selected(index: int) -> void:
	var id = option_button.get_item_id(index)
	var key = WaveType.find_key(id)
	player_layers[current_layer_index].wave_type = WaveType[key]
	_refresh()

func _on_previous_layer() -> void:
	if current_layer_index > 0:
		_save_from_ui()
		current_layer_index -= 1
		_update_ui()
		print(current_layer_index)
		_refresh()

func _on_next_layer() -> void:
	if current_layer_index < player_layers.size() - 1:
		_save_from_ui()
		current_layer_index += 1
		_update_ui()
		print(current_layer_index)
		_refresh()

func _on_toggle_op() -> void:
	if current_layer_index < player_ops.size():
		var all_ops = CombineOp.values()
		var next = (player_ops[current_layer_index] + 1) % all_ops.size()
		player_ops[current_layer_index] = next
		_update_combine_op_button()
		_refresh()
