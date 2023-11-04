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

## Called when the state chart step function is called.
signal state_stepped()

## Called when the state is receiving input.
signal state_input(event:InputEvent)

## Called when the state is receiving unhandled input.
signal state_unhandled_input(event:InputEvent)

## Called every frame while a delayed transition is pending for this state.
## Returns the initial delay and the remaining delay of the transition.
signal transition_pending(initial_delay:float, remaining_delay:float)


## Whether the state is currently active (internal flag, use active).
var _state_active = false

## Whether the current state is active.
var active:bool:
	get: return _state_active
	

## The currently active pending transition.
var _pending_transition:Transition = null

## Remaining time in seconds until the pending transition is triggered.
var _pending_transition_time:float = 0

## The transitions of this state.
var _transitions:Array[Transition] = []


## The state chart that owns this state.
@onready var _chart = _find_chart(get_parent())

## Finds the owning state chart by moving upwards.
func _find_chart(parent:Node):
	if parent is StateChart:
		return parent
	
	return _find_chart(parent.get_parent())	

## Runs a transition either immediately or delayed depending on the 
## transition settings.
func _run_transition(transition:Transition):
	if transition.delay_seconds > 0:
		_queue_transition(transition)
	else:
		_chart._run_transition(transition, self)
		
	

## Called when the state chart is built.
func _state_init():
	# disable state by default
	process_mode = Node.PROCESS_MODE_DISABLED
	_state_active = false
	_toggle_processing(false)
	
	# load transitions
	_transitions.clear()
	for child in get_children():
		if child is Transition:
			_transitions.append(child)
	
## Called when the state is entered. The parameter indicates whether the state
## is expected to immediately handle a transition after it has been entered.
## In this case the state should not automatically activate a default child state.
## This is to avoid a situation where a state is entered, activates a child then immediately
## exits and activates another child due to a transition.
func _state_enter(expect_transition:bool = false):
	# print("state_enter: " + name)
	_state_active = true
	
	process_mode = Node.PROCESS_MODE_INHERIT

	# enable processing if someone listens to our signal
	_toggle_processing(true)
	
	# emit the signal
	state_entered.emit()
	# check all transitions which have no event
	for transition in _transitions:
		if not transition.has_event and transition.evaluate_guard():
			# first match wins
			_run_transition(transition)

## Called when the state is exited.
func _state_exit():
	# print("state_exit: " + name)
	# cancel any pending transitions
	_pending_transition = null
	_pending_transition_time = 0
	_state_active = false
	# stop processing
	process_mode = Node.PROCESS_MODE_DISABLED
	_toggle_processing(false)
	
	# emit the signal
	state_exited.emit()

## Called when the state should be saved. The parameter is is the SavedState object
## of the parent state. The state is expected to add a child to the SavedState object
## under its own name. 
## 
## The child_levels parameter indicates how many levels of children should be saved.
## If set to -1 (default), all children should be saved. If set to 0, no children should be saved.
##
## This method will only be called if the state is active and should only be called on
## active children if children should be saved.
func _state_save(saved_state:SavedState, child_levels:int = -1):
	if not active:
		push_error("_state_save should only be called if the state is active.")
		return
	
	# create a new SavedState object for this state
	var our_saved_state := SavedState.new()
	our_saved_state.pending_transition_name = _pending_transition.name if _pending_transition != null else ""
	our_saved_state.pending_transition_time = _pending_transition_time
	# add it to the parent
	saved_state.add_substate(self, our_saved_state)

	if child_levels == 0:
		return

	# calculate the child levels for the children, -1 means all children
	var sub_child_levels = -1 if child_levels == -1 else child_levels - 1

	# save all children
	for child in get_children():
		if child is State and child.active:
			child._state_save(our_saved_state, sub_child_levels)


## Called when the state should be restored. The parameter is the SavedState object
## of the parent state. The state is expected to retrieve the SavedState object
## for itself from the parent and restore its state from it. 
##
## The child_levels parameter indicates how many levels of children should be restored.
## If set to -1 (default), all children should be restored. If set to 0, no children should be restored.
##
## If the state was not active when it was saved, this method still will be called
## but the given SavedState object will not contain any data for this state.
func _state_restore(saved_state:SavedState, child_levels:int = -1):
	# print("restoring state " + name)
	var our_saved_state = saved_state.get_substate_or_null(self)
	if our_saved_state == null:
		# if we are currently active, deactivate the state
		if active:
			_state_exit()
		# otherwise we are already inactive, so we don't need to do anything
		return

	# otherwise if we are currently inactive, activate the state
	if not active:
		_state_enter()
	# and restore any pending transition
	_pending_transition = get_node_or_null(our_saved_state.pending_transition_name) as Transition
	_pending_transition_time = our_saved_state.pending_transition_time
	
	# if _pending_transition != null:
	#	print("restored pending transition " + _pending_transition.name + " with time " + str(_pending_transition_time))
	# else:
	#	print("no pending transition restored")

	if child_levels == 0:
		return

	# calculate the child levels for the children, -1 means all children
	var sub_child_levels = -1 if child_levels == -1 else child_levels - 1

	# restore all children
	for child in get_children():
		if child is State:
			child._state_restore(our_saved_state, sub_child_levels)


## Called while the state is active.
func _process(delta:float):
	if Engine.is_editor_hint():
		return
		
	# emit the processing signal
	state_processing.emit(delta)
	# check if there is a pending transition
	if _pending_transition != null:
		_pending_transition_time -= delta
		
		# Notify interested parties that currently a transition is pending.
		transition_pending.emit(_pending_transition.delay_seconds, max(0, _pending_transition_time))
		
		# if the transition is ready, trigger it
		# and clear it.
		if _pending_transition_time <= 0:
			var transition_to_send = _pending_transition
			_pending_transition = null
			_pending_transition_time = 0
			# print("requesting transition from " + name + " to " + transition_to_send.to.get_concatenated_names() + " now")
			_chart._run_transition(transition_to_send, self)
			
	# evaluate monitored transitions
	for transition in _transitions:
		if transition.monitored and transition.evaluate_guard():
			# first match wins
			_run_transition(transition)

func _handle_transition(transition:Transition, source:State):
	push_error("State " + name + " cannot handle transitions.")
	

func _physics_process(delta:float):
	if Engine.is_editor_hint():
		return
	state_physics_processing.emit(delta)

## Called when the state chart step function is called.
func _state_step():
	state_stepped.emit()

func _input(event:InputEvent):
	state_input.emit(event)


func _unhandled_input(event:InputEvent):
	state_unhandled_input.emit(event)

## Handles the given event. Returns true if the event was consumed, false otherwise.
func _state_event(event:StringName) -> bool:
	if not active:
		return false

	# emit the event received signal
	event_received.emit(event)

	# check all transitions which have the event
	for transition in _transitions:
		if transition.event == event and transition.evaluate_guard():
			# print(name +  ": consuming event " + event)
			# first match wins
			_run_transition(transition)
			return true
	return false

## Queues the transition to be triggered after the delay.
## Executes the transition immediately if the delay is 0.
func _queue_transition(transition:Transition):
	# print("transitioning from " + name + " to " + transition.to.get_concatenated_names() + " in " + str(transition.delay_seconds) + " seconds" )
	# queue the transition for the delay time (0 means next frame)
	_pending_transition = transition
	_pending_transition_time = transition.delay_seconds
	
	# enable processing when we have a transition
	set_process(true)


func _get_configuration_warnings() -> PackedStringArray:
	var result = []
	# if not at least one of our ancestors is a StateChart add a warning
	var parent = get_parent()
	var found = false
	while is_instance_valid(parent):
		if parent is StateChart:
			found = true
			break
		parent = parent.get_parent()
	
	if not found:
		result.append("State is not a child of a StateChart. This will not work.")

	return result		


func _toggle_processing(active:bool):
	set_process(active and (_has_connections(state_processing) or _has_monitored_transition()))
	set_physics_process(active and _has_connections(state_physics_processing))
	set_process_input(active and _has_connections(state_input))
	set_process_unhandled_input(active and _has_connections(state_unhandled_input))

## Checks whether the given signal has connections. 
func _has_connections(sgnl:Signal) -> bool:
	return sgnl.get_connections().size() > 0

## Checks if at least one transsition is monitored
func _has_monitored_transition():
	for transition in _transitions:
		if transition.monitored:
			return true
	return false
