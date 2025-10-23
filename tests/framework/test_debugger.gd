extends Object

# the state chart we track
var _state_chart:StateChart

## Sets up the debugger to track the given state chart. If the given node is not 
## a state chart, it will search the children for a state chart. If no state chart
## is found, the debugger will be disabled.
func track(chart:StateChart):
	_state_chart = chart
	_connect_all_signals()
	print("BEGIN [%s]----------------------------------" % [_state_chart.name])


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		print("END [%s] ------------------------------------" % [_state_chart.name])
		

## Connects all signals from the currently processing state chart
func _connect_all_signals():
	if not is_instance_valid(_state_chart):
		return

	_state_chart.event_received.connect(_on_event_received)

	# find all state nodes below the state chart and connect their signals
	for child in _state_chart.get_children():
		if child is StateChartState:
			_connect_signals(child)


func _connect_signals(state:StateChartState):
	state.state_entered.connect(_on_state_entered.bind(state))
	state.state_exited.connect(_on_state_exited.bind(state))

	# recurse into children
	for child in state.get_children():
		if child is StateChartState:
			_connect_signals(child)
		if child is Transition:
			var callable = _on_before_transition.bind(child, state)
			child.taken.connect(callable)


func _on_before_transition(transition:Transition, source:StateChartState):
	print("%s [%s] [»] Transition: %s from %s to %s" % [Engine.get_process_frames(), _state_chart.name,transition.name, _state_chart.get_path_to(source), _state_chart.get_path_to(transition.resolve_target())])


func _on_event_received(event:StringName):
	print("%s [%s] [!] Event received: %s" % [Engine.get_process_frames(), _state_chart.name, event])

	
func _on_state_entered(state:StateChartState):
	print("%s [%s] [>] Enter: %s" % [Engine.get_process_frames(), _state_chart.name, state.name])


func _on_state_exited(state:StateChartState):
	print("%s [%s] [<] Exit: %s" % [Engine.get_process_frames(), _state_chart.name, state.name])

