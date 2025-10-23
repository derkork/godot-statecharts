class_name StateChartTestBase
extends GutTest

var _chart: StateChart

# ---- Wrappers for StateChart methods ----
## Sends an event to the default state chart.
func send_event(event: String) -> void:
	_chart.send_event(event)

## Sets an expression property on the default state chart.
@warning_ignore("shadowed_variable_base_class")
func set_expression_property(name: String, value: Variant) -> void:
	_chart.set_expression_property(name, value)

## Gets an expression property from the default state chart.
@warning_ignore("shadowed_variable_base_class")
func get_expression_property(name: String, default:Variant = null) -> Variant:
	return _chart.get_expression_property(name, default)	

## Sets the initial expression properties on the default state chart.
func set_initial_expression_properties(properties: Dictionary) -> void:
	_chart.initial_expression_properties = properties	

## Steps the default state chart.
func step()-> void:
	_chart.step()
	
# ---- Test specific helpers ---
func before_each() -> void:
	_chart = chart("default")


func assert_active(state: StateChartState) -> void:
	if not state.active:
		print_chart_state()
	assert_true(state.active, "Expected state " + state.name + " to be active")

func assert_inactive(state: StateChartState) -> void:
	if state.active:
		print_chart_state()
	assert_false(state.active, "Expected state " + state.name + " to be inactive")

## Completes the setup of the state chart by adding a debugger and adding it to the scene tree.
@warning_ignore("shadowed_variable")
func finish_setup(chart:StateChart = _chart) -> void:
	var debugger = preload("test_debugger.gd").new()
	debugger.track(chart)
	autofree(debugger)

	add_child(chart)
	
	# wait one frame so the state chart can get into the initial state
	await wait_frames(1, "waiting for state chart to become ready")


# ---- StateChart Builder DSL ----
## Creates a new state chart instance and ensures it gets cleaned up after the test.
@warning_ignore("shadowed_variable_base_class")
func chart(name:String) -> StateChart:
	var result:StateChart = StateChart.new()
	result.name = name
	autoqfree(result)
	return result
	

## Creates a new compound state and adds it to the given parent or to the default 
## state chart if no parent is given.
@warning_ignore("shadowed_variable_base_class")
func compound_state(name: String, parent: Variant = null ) -> CompoundState:
	# parent must be either null, a StateChartState, or a StateChart
	assert(parent == null or parent is StateChartState or parent is StateChart)
	var state: CompoundState = CompoundState.new()
	state.name = name
	if parent != null:
		parent.add_child(state)
		if parent is CompoundState and parent.initial_state.is_empty():
			parent.initial_state = parent.get_path_to(state)
	else:
		_chart.add_child(state)
	return state

## Creates a new parallel state and adds it to the given parent or to the default 
## state chart if no parent is given.
@warning_ignore("shadowed_variable_base_class")
func parallel_state(name: String, parent: Variant = null) -> ParallelState:
	# parent must be either null, a StateChartState, or a StateChart
	assert(parent == null or parent is StateChartState or parent is StateChart)
	var state: ParallelState = ParallelState.new()
	state.name = name
	if parent != null:
		parent.add_child(state)
		if parent is CompoundState and parent.initial_state.is_empty():
			parent.initial_state = parent.get_path_to(state)
	else:
		_chart.add_child(state)

	return state

## Creates a new atomic state and adds it to the given parent state chart state.
@warning_ignore("shadowed_variable_base_class")
func atomic_state( name: String, parent: StateChartState) -> AtomicState:
	assert(not(parent is AtomicState))
	assert(not(parent is HistoryState))
	
	var state: AtomicState = AtomicState.new()
	state.name = name
	parent.add_child(state)
	if parent is CompoundState and parent.initial_state.is_empty():
		parent.initial_state = parent.get_path_to(state)
	return state
	

## Creates a new transition from one state to another with optional event, delay, and guard.
@warning_ignore("shadowed_variable_base_class")
func transition(from: StateChartState, to: StateChartState, event: String = "", delay: String = "0", guard: Guard = null) -> Transition:
	@warning_ignore("shadowed_variable")
	var transition: Transition = Transition.new()
	if event.is_empty():
		transition.name = "Automatic to %s" % [to.name]
	else:
		transition.name = "On %s to %s" % [event, to.name] 
	from.add_child(transition)
	transition.to = transition.get_path_to(to)
	transition.event = event
	transition.guard = guard
	transition.delay_in_seconds = delay
	return transition

## Creates a new history state and adds it to the given parent compound state.
@warning_ignore("shadowed_variable_base_class")
func history_state(name: String, parent: CompoundState, default_state:StateChartState, deep:bool = false) -> HistoryState:
	var state: HistoryState = HistoryState.new()
	state.name = name
	state.deep = deep
	parent.add_child(state)
	state.default_state = state.get_path_to(default_state)
	# we don't set the initial state here, as it is not needed for history states
	return state

## Creates a new expression guard with the given expression.
func expression_guard(expression: String) -> ExpressionGuard:
	var guard: ExpressionGuard = ExpressionGuard.new()
	guard.expression = expression
	return guard

## Creates a new state is active guard for the given state.	
func state_is_active_guard(state: StateChartState) -> StateIsActiveGuard:
	var guard: StateIsActiveGuard = StateIsActiveGuard.new()
	# we can only know the path after the state is added to the tree, so we need to do
	# a bit of trickery... 
	state.ready.connect(func(): guard.state = state.get_path())
	return guard

## Creates a new all of guard that combines the given guards.	
func all_of_guard(guard:Array[Guard]) -> AllOfGuard:
	@warning_ignore("shadowed_variable")
	var all_of_guard: AllOfGuard = AllOfGuard.new()
	all_of_guard.guards = guard
	return all_of_guard

## Creates a new any of guard that combines the given guards.	
func any_of_guard(guard:Array[Guard]) -> AnyOfGuard:
	@warning_ignore("shadowed_variable")
	var any_of_guard: AnyOfGuard = AnyOfGuard.new()
	any_of_guard.guards = guard
	return any_of_guard

## Creates a new not guard that negates the given guard.
func not_guard(guard:Guard) -> NotGuard:
	@warning_ignore("shadowed_variable")
	var not_guard: NotGuard = NotGuard.new()
	not_guard.guard = guard
	return not_guard


# ---- Debug helpers ----
## Prints a tree of the current state chart and its states.
## For each state prints its name, type, and whether it is active or inactive.
## If a state has a pending transition, it is printed as a child line with the remaining time.
## For history states, prints the contents of the currently saved history if any.
func print_chart_state() -> void:
	var lines: Array[String] = []
	if is_instance_valid(_chart):
		lines.append("StateChart")
		_append_state_lines(_chart, "  ", lines)
	else:
		lines.append("<no StateChart>")
	for line in lines:
		print(line)


func _append_state_lines(root: Node, indent: String, lines: Array[String]) -> void:
	for child in root.get_children():
		if child is StateChartState:
			var state := child as StateChartState
			var active_text: String = "active" if state.active else "inactive"
			var type_letter := _state_type_letter(state)
			lines.append("%s- [%s] %s (%s)" % [indent, type_letter, state.name, active_text])
			# Pending transition info as a child line if present
			if is_instance_valid(state._pending_transition):
				lines.append("%s  -> %s (%.2f)" % [indent, state._pending_transition.name, state._pending_transition_remaining_delay])
			# History contents if present
			if state is HistoryState and is_instance_valid((state as HistoryState).history):
				var paths := _collect_saved_state_paths((state as HistoryState).history, "")
				if paths.size() > 0:
					lines.append("%s  history: %s" % [indent, ", ".join(paths)])
			# Recurse into child states
			_append_state_lines(child, indent + "  ", lines)

func _state_type_letter(state: StateChartState) -> String:
	if state is AtomicState:
		return "A"
	if state is CompoundState:
		return "C"
	if state is ParallelState:
		return "P"
	if state is HistoryState:
		return "H"
	return "?"

func _collect_saved_state_paths(saved: SavedState, prefix: String) -> Array[String]:
	var result: Array[String] = []
	if not is_instance_valid(saved):
		return result
	for key in saved.child_states.keys():
		var name_str := str(key)
		var path := name_str if prefix.is_empty() else "%s/%s" % [prefix, name_str]
		result.append(path)
		var child_saved: SavedState = saved.child_states[key]
		if is_instance_valid(child_saved):
			for sub in _collect_saved_state_paths(child_saved, path):
				result.append(sub)
	return result
