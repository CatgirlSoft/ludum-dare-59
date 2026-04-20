class_name Curve_Class
extends Control

@onready var curve: Control = $"."
@onready var option_button: OptionButton = $OptionButton

@onready var layer_label: Label = $Label2
@onready var combine_op_button: Button = $Button3

@export_group("Node_reference")
@export var amplitude_slider: VSlider
@export var phase_slider: HSlider
@export var frequency_slider: Knob

@export var percentage_label: Label

@export var previous_layer_button: Button
@export var next_layer_button: Button

@export var previous_wave_type: TextureButton
@export var next_wave_type: TextureButton

@export var curve_addition_type: TextureButton

@export var selected_wave_texture_rect: TextureRect

@export var right_screen: Control
@export var right_color_rect: ColorRect
@export var left_screen: Control
@export var left_color_rect: ColorRect

@export var combination_add_label: Label
@export var progress_bar: TextureProgressBar

@export_group("Wave_Images")
@export var sine_image: Texture2D
@export var square_image: Texture2D
@export var saw_image: Texture2D
@export var triangle_image: Texture2D


@export_group("Value")
@export var number_of_layers: int = 1

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

	recalculate_player_layers()

func recalculate_player_layers():
	player_layers = []
	player_ops = []
	for i in range(target_layers.size()):
		player_layers.append(_first_layer())
	for i in range(target_layers.size() - 1):
		player_ops.append(CombineOp.ADD)
	current_layer_index = 0
	layer_changed.emit(current_layer_index)
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

func compare(a: Array, b: Array) -> float:
	#var min_size = mini(a.size(), b.size())
	#var sum = 0.0
	#for i in  range(min_size):
		#var diff = a[i] - b[i]
		#sum += diff * diff
	#return sum / min_size
	var min_size = mini(a.size(), b.size())
	if min_size == 0:
		return 0.0

	var mean_a := 0.0
	var mean_b := 0.0
	for i in range(min_size):
		mean_a += a[i]
		mean_b += b[i]
	mean_a /= min_size
	mean_b /= min_size
	
	var num := 0.0
	var den_a := 0.0
	var den_b := 0.0
	for i in range(min_size):
		var da = a[i] - mean_a
		var db = b[i] - mean_b
		num += da * db
		den_a += da * da
		den_b += db * db
	
	var correlation := 0.0
	if den_a > 0.0 and den_b > 0.0:
		correlation = num / sqrt(den_a * den_b)

	var rms_a := sqrt(den_a / min_size)
	var rms_b := sqrt(den_b / min_size)
	var amp_penalty := 1.0
	if rms_b > 0.0:
		var ratio = rms_a / rms_b
		amp_penalty = 1.0 - clampf(abs(ratio - 1.0), 0.0, 1.0)
	return clampf((correlation * 0.7 + amp_penalty * 0.3), 0.0, 1.0)

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
			"amplitude": randf_range(max(amplitude_slider.min_value, 20.0), min(amplitude_slider.max_value, 80.0)),
			"frequency": randf_range(max(frequency_slider.min_value, 0.3), min(frequency_slider.max_value, 1.7)),
			"phase":     randf_range(max(phase_slider.min_value, 1.0), min(phase_slider.max_value, 7.0)),
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

func _update_shader(rect: ColorRect, data: Array) -> void:
	var img = Image.create(data.size(), 1, false, Image.FORMAT_RF)
	for i in range(data.size()):
		var normalized = (data[i] / -amplitude + 1.0) / 2.0
		img.set_pixel(i, 0, Color(normalized, 0, 0, 1))
	var tex = ImageTexture.create_from_image(img)
	(rect.material as ShaderMaterial).set_shader_parameter("samples", tex)
	

func _update_wave_texture(type: WaveType) -> void:
	match type:
		WaveType.SINE:
			selected_wave_texture_rect.texture = sine_image
		WaveType.SQUARE:
			selected_wave_texture_rect.texture = square_image
		WaveType.SAW:
			selected_wave_texture_rect.texture = saw_image
		WaveType.TRIANGLE:
			selected_wave_texture_rect.texture = triangle_image

func _update_ui() -> void:
	var layer = player_layers[current_layer_index]
	amplitude_slider.value = layer.amplitude
	frequency_slider.value = layer.frequency
	phase_slider.value = layer.phase
	_update_wave_texture(player_layers[current_layer_index].wave_type)
	if current_layer_index < player_ops.size():
		combination_add_label.text = CombineOp.find_key(player_ops[current_layer_index])
	else:
		combination_add_label.text = "UNDEFINED"
	_update_combine_op_button()
	

func _update_combine_op_button() -> void:
	if current_layer_index < player_ops.size():
		combine_op_button.text = "OP:" + CombineOp.find_key(player_ops[current_layer_index])
		combination_add_label.text = CombineOp.find_key(player_ops[current_layer_index])


func _save_from_ui() -> void:
	player_layers[current_layer_index] = {
		"amplitude": amplitude_slider.value,
		"frequency": frequency_slider.value,
		"phase":     phase_slider.value,
		"wave_type": player_layers[current_layer_index].wave_type
	}

func score() -> float:
	var similarity = compare(samples, target)
	var percent = similarity * 100.0
	percentage_label.text = "Similarity:\n " + str(percent).pad_decimals(2) + "%"
	progress_bar.value = percent
	return percent

func _refresh() -> void:
	samples = _evaluate_layers(player_layers, player_ops, number_of_samples)
	var new_score = score()
	score_changed.emit(new_score)
	_update_shader(left_color_rect, samples)
	_update_shader(right_color_rect, target)
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
	_update_wave_texture(player_layers[current_layer_index].wave_type)
	_refresh()

func _on_next_curve_pressed():
	var types = WaveType.values()
	var current = player_layers[current_layer_index].wave_type
	var index = types.find(current)
	player_layers[current_layer_index].wave_type = types[(index + 1) % types.size()]
	_update_wave_texture(player_layers[current_layer_index].wave_type)
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
	else:
		combination_add_label.text = "UNDEFINED"
