@tool
@icon("compound_state.svg")
## A compound state is a state that has multiple sub-states of which exactly one can
## be active at any given time.
class_name CompoundState
extends State

## Called when a child state is entered.
signal child_state_entered()

## Called when a child state is exited.
signal child_state_exited()

## The initial state which should be activated when this state is activated.
@export_node_path("State") var initial_state:NodePath:
	get:
		return initial_state
	set(value):
		initial_state = value
		update_configuration_warnings() 


## The currently active substate.
var _active_state:State = null

## The initial state
@onready var _initial_state:State = get_node_or_null(initial_state)

## The history states of this compound state.
var _history_states:Array[HistoryState] = []
## Whether any of the history states needs a deep history.
var _needs_deep_history = false

func _state_init():
	super._state_init()

	# check if we have any history states
	for child in get_children():
		if child is HistoryState:
			var child_as_history_state:HistoryState = child as HistoryState
			_history_states.append(child_as_history_state)
			# remember if any of the history states needs a deep history
			_needs_deep_history = _needs_deep_history or child_as_history_state.deep

	# initialize all substates. find all children of type State and call _state_init on them.
	for child in get_children():
		if child is State:
			var child_as_state:State = child as State
			child_as_state._state_init()
			child_as_state.state_entered.connect(func(): child_state_entered.emit())
			child_as_state.state_exited.connect(func(): child_state_exited.emit())

func _state_enter(expect_transition:bool = false):
	super._state_enter()
	# activate the initial state unless we expect a transition
	if not expect_transition:
		if _initial_state != null:
			_active_state = _initial_state
			_active_state._state_enter()
		else:
			push_error("No initial state set for state '" + name + "'.")

func _state_step():
	super._state_step()
	if _active_state != null:
		_active_state._state_step()

func _state_save(saved_state:SavedState, child_levels:int = -1):
	super._state_save(saved_state, child_levels)

	# in addition save all history states, as they are never active and normally would not be saved
	var parent = saved_state.get_substate_or_null(self)
	if parent == null:
		push_error("Probably a bug: The state of '" + name + "' was not saved.")
		return

	for history_state in _history_states:
		history_state._state_save(parent, child_levels)

func _state_restore(saved_state:SavedState, child_levels:int = -1):
	super._state_restore(saved_state, child_levels)

	# in addition check if we are now active and if so determine the current active state
	if active:
		# find the currently active child
		for child in get_children():
			if child is State and child.active:
				_active_state = child
				break

func _state_exit():
	# if we have any history states, we need to save the current active state
	if _history_states.size() > 0:
		var saved_state = SavedState.new()
		# we save the entire hierarchy if any of the history states needs a deep history
		# otherwise we only save this level. This way we can save memory and processing time
		_state_save(saved_state, -1 if _needs_deep_history else 1)

		# now save the saved state in all history states
		for history_state in _history_states:
			# when saving history it's ok when we save deep history in a history state that doesn't need it
			# because at restore time we will use the state's deep flag to determine if we need to restore
			# the entire hierarchy or just this level. This way we don't need multiple copies of the same
			# state hierarchy.
			history_state.history = saved_state

	# deactivate the current state
	if _active_state != null:
		_active_state._state_exit()
		_active_state = null
	super._state_exit()


func _process_transitions(event:StringName, property_change:bool = false) -> bool:
	if not active:
		return false

	# forward to the active state
	if is_instance_valid(_active_state):
		if _active_state._process_transitions(event, property_change):
			# emit the event_received signal, unless this is a property change
			if not property_change:
				self.event_received.emit(event)
			return true

	# if the event was not handled by the active state, we handle it here
	# base class will also emit the event_received signal
	return super._process_transitions(event, property_change)





func add_child(node:Node, force_readable_name:bool = false, internal:InternalMode = INTERNAL_MODE_DISABLED) -> void:
	super.add_child(node, force_readable_name, internal)
	# when a child is added in the editor and the child is a state
	# and we don't have an initial state yet, set the initial state 
	# to the newly added child
	if Engine.is_editor_hint() and node is State:
		if initial_state.is_empty():
			# the newly added node may have a random name now, 
			# so we need to defer the call to build a node path
			# to the next frame, so the editor has time to rename
			# the node to its final name
			(func(): initial_state = get_path_to(node)).call_deferred()
			

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = super._get_configuration_warnings()
	
	# count the amount of child states
	var child_count = 0
	for child in get_children():
		if child is State:
			child_count += 1

	if child_count < 2:
		warnings.append("Compound states should have at two child states.")
		
	var the_initial_state = get_node_or_null(initial_state)
	
	if not is_instance_valid(the_initial_state):
		warnings.append("Initial state could not be resolved, is the path correct?")
		
	elif the_initial_state.get_parent() != self:
		warnings.append("Initial state must be a direct child of this compound state.")
	
	return warnings
