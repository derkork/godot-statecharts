class_name StateChartTestBase
extends GutTest

var _chart: StateChart

# ---- Wrappers for StateChart methods ----
func send_event(event: String) -> void:
	_chart.send_event(event)

@warning_ignore("shadowed_variable_base_class")
func set_expression_property(name: String, value: Variant) -> void:
	_chart.set_expression_property(name, value)

@warning_ignore("shadowed_variable_base_class")
func get_expression_property(name: String, default:Variant = null) -> Variant:
	return _chart.get_expression_property(name, default)	

func set_initial_expression_properties(properties: Dictionary) -> void:
	_chart.initial_expression_properties = properties	

func step()-> void:
	_chart.step()
	
# ---- Test specific helpers ---
func before_each() -> void:
	_chart = StateChart.new()


func after_each() -> void:
	var parent = _chart.get_parent()
	if is_instance_valid(parent):
		parent.remove_child(_chart)
	_chart.free()

func assert_active(state: StateChartState) -> void:
	if not state.active:
		print_chart_state()
	assert_true(state.active, "Expected state " + state.name + " to be active")

func assert_inactive(state: StateChartState) -> void:
	if state.active:
		print_chart_state()
	assert_false(state.active, "Expected state " + state.name + " to be inactive")

func finish_setup() -> void:
	var debugger = preload("test_debugger.gd").new()
	debugger.track(_chart)
	autofree(debugger)

	add_child(_chart)
	
	# wait one frame so the state chart can get into the initial state
	await wait_frames(1, "waiting for state chart to become ready")


# ---- StateChart Builder DSL ----

@warning_ignore("shadowed_variable_base_class")
func compound_state(name: String, parent: StateChartState = null ) -> CompoundState:
	var state: CompoundState = CompoundState.new()
	state.name = name
	if parent != null:
		parent.add_child(state)
		if parent is CompoundState and parent.initial_state.is_empty():
			parent.initial_state = parent.get_path_to(state)
	else:
		_chart.add_child(state)
	return state


@warning_ignore("shadowed_variable_base_class")
func parallel_state(name: String, parent: StateChartState = null) -> ParallelState:
	var state: ParallelState = ParallelState.new()
	state.name = name
	if parent != null:
		parent.add_child(state)
		if parent is CompoundState and parent.initial_state.is_empty():
			parent.initial_state = parent.get_path_to(state)
	else:
		_chart.add_child(state)

	return state


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


@warning_ignore("shadowed_variable_base_class")
func history_state(name: String, parent: CompoundState, default_state:StateChartState, deep:bool = false) -> HistoryState:
	var state: HistoryState = HistoryState.new()
	state.name = name
	state.deep = deep
	parent.add_child(state)
	state.default_state = state.get_path_to(default_state)
	# we don't set the initial state here, as it is not needed for history states
	return state

func expression_guard(expression: String) -> ExpressionGuard:
	var guard: ExpressionGuard = ExpressionGuard.new()
	guard.expression = expression
	return guard

	
func state_is_active_guard(state: StateChartState) -> StateIsActiveGuard:
	var guard: StateIsActiveGuard = StateIsActiveGuard.new()
	# we can only know the path after the state is added to the tree, so we need to do
	# a bit of trickery... 
	state.ready.connect(func(): guard.state = state.get_path())
	return guard

	
func all_of_guard(guard:Array[Guard]) -> AllOfGuard:
	@warning_ignore("shadowed_variable")
	var all_of_guard: AllOfGuard = AllOfGuard.new()
	all_of_guard.guards = guard
	return all_of_guard

	
func any_of_guard(guard:Array[Guard]) -> AnyOfGuard:
	@warning_ignore("shadowed_variable")
	var any_of_guard: AnyOfGuard = AnyOfGuard.new()
	any_of_guard.guards = guard
	return any_of_guard


func not_guard(guard:Guard) -> NotGuard:
	@warning_ignore("shadowed_variable")
	var not_guard: NotGuard = NotGuard.new()
	not_guard.guard = guard
	return not_guard


# ---- Debug helpers ----
func print_chart_state() -> void:
	# Prints a tree of the current state chart and its states.
	# For each state prints its name and whether it is active or inactive.
	# If a state has a pending transition, it is printed as a child line with the remaining time.
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
			var active_text: String = "active" if (child as StateChartState).active else "inactive"
			lines.append("%s- %s (%s)" % [indent, (child as StateChartState).name, active_text])
			# Pending transition info as a child line if present
			if is_instance_valid((child as StateChartState)._pending_transition):
				lines.append("%s  -> %s (%.2f)" % [indent, (child as StateChartState)._pending_transition.name, (child as StateChartState)._pending_transition_remaining_delay])
			# Recurse into child states
			_append_state_lines(child, indent + "  ", lines)
