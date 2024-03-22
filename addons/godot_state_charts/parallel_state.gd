@tool
@icon("parallel_state.svg")
## A parallel state is a state which can have sub-states, all of which are active
## when the parallel state is active.
class_name ParallelState
extends State

# all children of the state
var _sub_states:Array[State] = []

func _state_init():
	super._state_init()
	# find all children of this state which are states
	for child in get_children():
		if child is State:
			_sub_states.append(child)
			child._state_init()

	# since there is no state transitions between parallel states, we don't need to
	# subscribe to events from our children




func _state_enter(expect_transition:bool = false):
	super._state_enter()
	# enter all children
	for child in _sub_states:
		child._state_enter()
	
func _state_exit():
	# exit all children
	for child in _sub_states:
		child._state_exit()
	
	super._state_exit()

func _state_step():
	super._state_step()
	for child in _sub_states:
		child._state_step()

func _process_transitions(event:StringName, property_change:bool = false) -> bool:
	if not active:
		return false

	# forward to all children
	var handled := false
	for child in _sub_states:
		var child_handled_it = child._process_transitions(event, property_change)
		handled = handled or child_handled_it

	# if any child handled this, we don't touch it anymore
	if handled:
		# emit the event_received signal for completeness
		# unless it was a property change
		if not property_change:
			self.event_received.emit(event)
		return true

	# otherwise handle it ourselves
	# defer to the base class
	return super._process_transitions(event, property_change)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = super._get_configuration_warnings()
	
	var child_count = 0
	for child in get_children():
		if child is State:
			child_count += 1
	
	if child_count < 2:
		warnings.append("Parallel states should have at least two child states.")
	
	
	return warnings
