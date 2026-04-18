@abstract
class_name State

## Called when the State is initiated
@abstract func ready() -> void

## Called when the machine transitions to this state
@abstract func enter() -> void

## Called when this state ends
@abstract func exit() -> void

## Called to to test parameter for any possible change in State
@abstract func switch_state() -> void

## Called in Godot's main update cycle 
@abstract func process(_delta: float) -> void

## Called in Godot's main physics update cycle
@abstract func physics_process(_delta: float) -> void

## Called to get the name of the state
@abstract func get_state_name() -> String
