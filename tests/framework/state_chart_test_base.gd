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
	remove_child(_chart)
	_chart.free()

func assert_active(state: StateChartState) -> void:
	assert_true(state.active, "Expected state " + state.name + " to be active")

func assert_inactive(state: StateChartState) -> void:
	assert_false(state.active, "Expected state " + state.name + " to be inactive")

func finish_setup() -> void:
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
