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


func _handle_transition(transition:Transition, source:State):
	# resolve the target state
	var target = transition.resolve_target()
	if not target is State:
		push_error("The target state '" + str(transition.to) + "' of the transition from '" + source.name + "' is not a state.")
		return
	
	# the target state can be
	# 0. this state. in this case just activate the state and all its children.
	#    this can happen when a child state transfers back to its parent state.
	# 1. a direct child of this state. this is the easy case in which
	#    we will do nothing, because our direct children are always active.
	# 2. a descendant of this state. in this case we find the direct child which
	#    is the ancestor of the target state and then ask it to perform
	#    the transition.
	# 3. no descendant of this state. in this case, we ask our parent state to
	#    perform the transition

	if target == self:
		# exit this state
		_state_exit()
		# then re-enter it
		_state_enter(false)
		return

	if target in get_children():
		# all good, nothing to do.
		return
		
	if self.is_ancestor_of(target):
		# find the child which is the ancestor of the new target.
		for child in get_children():
			if child.is_ancestor_of(target):
				# ask child to handle the transition
				child._handle_transition(transition, source)
				return
		return
	
	# ask the parent
	get_parent()._handle_transition(transition, source)

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

func _state_event(event:StringName) -> bool:
	if not active:
		return false

	# forward event to all children
	var handled := false
	for child in _sub_states:
		var child_handled_it = child._state_event(event)
		handled = handled or child_handled_it

	# if any child handled the event, we don't touch it anymore
	if handled:
		# emit the event_received signal for completeness
		self.event_received.emit(event)
		return true

	# otherwise handle it ourselves
	# base class will also emit the event_received signal
	return super._state_event(event)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = super._get_configuration_warnings()
	if get_child_count() == 0:
		warnings.append("Parallel states should have at least one child state.")
	
	return warnings
