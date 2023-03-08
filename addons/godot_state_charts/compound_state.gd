@tool
@icon("compound_state.svg")
## A compound state is a state that has multiple sub-states of which exactly one can
## be active at any given time.
class_name CompoundState
extends State

## The initial state which should be activated when this state is activated.
@export_node_path("State") var initial_state:NodePath:
	get:
		return initial_state
	set(value):
		initial_state = value
		update_configuration_warnings() 

## The currently active substate.
var _active_state:State = null
@onready var _initial_state:State = get_node_or_null(initial_state)


func _state_init():
	super._state_init()

	# initialize all substates. find all children of type State and call _state_init on them.
	for child in get_children():
		if child is State:
			var child_as_state:State = child as State
			child_as_state._state_init()


func _state_enter():
	super._state_enter()
	# activate the initial state
	if _initial_state != null:
		_active_state = _initial_state
		_active_state._state_enter()

func _state_exit():
	# deactivate the current state
	if _active_state != null:
		_active_state._state_exit()
		_active_state = null
	super._state_exit()

func _state_event(event:StringName) -> bool:
	if not active:
		return false

	# forward the event to the active state
	if is_instance_valid(_active_state):
		if _active_state._state_event(event):
			# emit the event_received signal
			self.event_received.emit(event)
			return true

	# if the event was not handled by the active state, we handle it here
	# base class will also emit the event_received signal
	return super._state_event(event)


func _handle_transition(transition:Transition, source:State):
	print("CompoundState._handle_transition: " + name + " from " + source.name + " to " + str(transition.to))
	# resolve the target state
	var target = transition.resolve_target()
	if not target is State:
		push_error("The target state '" + str(transition.to) + "' of the transition from '" + source.name + "' is not a state.")
		return
	
	# the target state can be
	# 1. a direct child of this state. this is the easy case in which
	#    we will deactivate the current _active_state and activate the targer
	# 2. a descendant of this state. in this case we find the direct child which
	#    is the ancestor of the target state, activate it and then ask it to perform
	#    the transition.
	# 3. no descendant of this state. in this case, we ask our parent state to
	#    perform the transition

	if target in get_children():
		# all good, now first deactivate the current state
		if is_instance_valid(_active_state):
			_active_state._state_exit()

		# then activate the new state
		_active_state = target
		_active_state._state_enter()
		return
		
	if self.is_ancestor_of(target):
		# find the child which is the ancestor of the new target.
		for child in get_children():
			if child.is_ancestor_of(target):
				# found it. 
				# change active state if necessary
				if _active_state != child:
					if is_instance_valid(_active_state):
						_active_state._state_exit()

					_active_state = child
					_active_state._state_enter()
					
				# ask child to handle the transition
				child._handle_transition(transition, source)
				return
		return
	
	# ask the parent
	get_parent()._handle_transition(transition, source)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings = super._get_configuration_warnings()
	if get_child_count() == 0:
		warnings.append("Compound states should have at least one child state.")
		
	var the_initial_state = get_node_or_null(initial_state)
	
	if not is_instance_valid(the_initial_state):
		warnings.append("Initial state could not be resolved, is the path correct?")
		
	elif the_initial_state.get_parent() != self:
		warnings.append("Initial state must be a direct child of this compound state.")
	
	return warnings
