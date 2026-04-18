extends Label

@export var state_machine: StateMachine
@export var state_prefix: String
@export var state_suffix: String = "State"

func _process(_delta: float) -> void:
	var state: String = state_machine.current_state.get_state_name()
	state = state.substr(state_prefix.length())
	state = state.substr(0, state.length() - 5)
	text = state
