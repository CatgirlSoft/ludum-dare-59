extends Control

@onready var curve: Control = $"."
@onready var option_button: OptionButton = $OptionButton

var amplitude = 100.0
var frequency = 0.1
var phase = 0

@export var x_size = 5
@export var step = 0.1

var samples = []
var target = []

enum WaveType {
	SINE,
	SQUARE,
	SAW,
	TRIANGLE
}

var wave_type = WaveType.SINE

func _ready() -> void:
	for en in WaveType.keys():
		option_button.add_item(en, WaveType[en])
	option_button.select(0)
	target = generate_random(10)
	samples = generate(10)
	
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
			Vector2((x_size * i) - (x_size * 100 + 30), samples[i]),
			Vector2((x_size * (i + 1) - (x_size * 100 + 30)), samples[i + 1]),
			Color.ALICE_BLUE, 1, true
		)
	for i in range(target.size() - 1):
		draw_line(
			Vector2(x_size * i, target[i]),
			Vector2(x_size * (i + 1), target[i + 1]),
			Color.ALICE_BLUE, 1, true
		)

func generate(number_samples: int) -> Array:
	var inner = []

	var x = 0.0
	while x < number_samples:
		var time = frequency * x
		var value = amplitude * wave(time - phase, wave_type)
		inner.append(value)
		x += step
	return inner

func generate_random(number_samples: int) -> Array:
	var inner = []
	
	var target_amplitude = randf_range(0.0, 100.0)
	var target_frequency = randf_range(0.0, 2.0)
	var target_phase = randf_range(0.0, 10.0)
	var rand_type = WaveType.keys()[randi() % WaveType.size()]

	var x = 0.0
	while x < number_samples:
		var time = target_frequency * x
		var value = target_amplitude * wave(time - target_phase, WaveType[rand_type])
		inner.append(value)
		x += step
	return inner


func _on_amplitude_value_changed(value: float) -> void:
	amplitude = value
	samples = generate(10)
	#var score = combined_score(samples, target)
	#print(score)
	queue_redraw()

func _on_phase_value_changed(value: float) -> void:
	phase = value
	samples = generate(10)
	#var score = combined_score(samples, target)
	#print(score)
	queue_redraw()

func _on_frequency_value_changed(value: float) -> void:
	frequency = value
	samples = generate(10)
	#var score = combined_score(samples, target)
	#print(score)
	queue_redraw()

func _on_option_button_item_selected(index: int) -> void:
	var id = option_button.get_item_id(index)
	var key = WaveType.find_key(id)
	wave_type = WaveType[key]
	samples = generate(10)
	#var score = combined_score(samples, target)
	#print(score)
	queue_redraw()
