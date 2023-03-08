@tool
## This class represents a state that can be either active or inactive.
class_name State
extends Node

## Called when the state is entered.
signal state_entered()

## Called when the state is exited.
signal state_exited()

## Called when the state receives an event. Only called if the state is active.
signal event_received(event:StringName)

## Called when the state is processing.
signal state_processing(delta:float)

## Called when the state is physics processing.
signal state_physics_processing(delta:float)

## Whether the current state is active.
var active:bool:
	get: return process_mode != Node.PROCESS_MODE_DISABLED

## The currently active pending transition.
var _pending_transition:Transition = null

## Remaining time in seconds until the pending transition is triggered.
var _pending_transition_time:float = 0

var _transitions:Array[Transition] = []

func _load_transitions() -> Array[Transition]:
	var result:Array[Transition] = []
	for child in get_children():
		if child is Transition:
			result.append(child)
	return result

func _state_init():
	# disable state by default
	process_mode = Node.PROCESS_MODE_DISABLED
	# load transitions
	_transitions = _load_transitions()
	
## Called when the state is entered.
func _state_enter():
	print("state_enter: " + name)
	process_mode = Node.PROCESS_MODE_INHERIT
	# emit the signal
	state_entered.emit()
	# check all transitions which have no event
	for transition in _transitions:
		if not transition.has_event and transition.evaluate_guard():
			# first match wins
			_queue_transition(transition)
			

## Called when the state is exited.
func _state_exit():
	print("state_exit: " + name)
	# cancel any pending transitions
	_pending_transition = null
	_pending_transition_time = 0
	# stop processing
	process_mode = Node.PROCESS_MODE_DISABLED
	# emit the signal
	state_exited.emit()


## Called while the state is active.
func _process(delta:float):
	if Engine.is_editor_hint():
		return
		
	# emit the processing signal
	state_processing.emit(delta)
	# check if there is a pending transition
	if _pending_transition != null:
		_pending_transition_time -= delta
		# if the transition is ready, trigger it
		# and clear it.
		if _pending_transition_time <= 0:
			var transition_to_send = _pending_transition
			_pending_transition = null
			_pending_transition_time = 0
			print("requesting transition from " + name + " to " + transition_to_send.to.get_concatenated_names() + " now")
			_handle_transition(transition_to_send, self)


func _handle_transition(transition:Transition, source:State):
	push_error("State " + name + " cannot handle transitions.")
	

func _physics_process(delta:float):
	if Engine.is_editor_hint():
		return
	state_physics_processing.emit(delta)


## Handles the given event. Returns true if the event was consumed, false otherwise.
func _state_event(event:StringName) -> bool:
	if not active:
		return false

	# emit the event received signal
	event_received.emit(event)

	# check all transitions which have the event
	for transition in _transitions:
		if transition.event == event and transition.evaluate_guard():
			print(name +  ": consuming event " + event)
			# first match wins
			_queue_transition(transition)
			return true
	return false

## Queues the transition to be triggered after the delay.
## Executes the transition immediately if the delay is 0.
func _queue_transition(transition:Transition):
	print("transitioning from " + name + " to " + transition.to.get_concatenated_names() + " in " + str(transition.delay_seconds) + " seconds" )
	# queue the transition for the delay time (0 means next frame)
	_pending_transition = transition
	_pending_transition_time = transition.delay_seconds


func _get_configuration_warnings() -> PackedStringArray:
	return []
		
