## This is the remote part of the editor debugger. It attaches to a state
## chart similar to the in-game debugger and forwards signals and debug
## information to the editor. 


const DebuggerMessage = preload("editor_debugger_message.gd")

# the state chart we track
var _state_chart:StateChart 

# whether to send transitions to the editor
var _ignore_transitions:bool = true
# whether to send events to the editor
var _ignore_events:bool = true


## Sets up the debugger remote to track the given state chart.
func _init(state_chart:StateChart):

	_state_chart = state_chart

	if not is_instance_valid(_state_chart):
		push_error("Probable bug: State chart is not valid. Please report this bug.")

	_register_settings_updates()

	# send initial state chart
	DebuggerMessage.state_chart_added(_state_chart)
	# prepare signals and send initial state of all states
	_prepare()

func _register_settings_updates():
	# print("Registering settings updates for ", _state_chart.get_path())
	if not _state_chart.is_inside_tree():
		return
	
	EngineDebugger.register_message_capture(DebuggerMessage.SETTINGS_UPDATED_MESSAGE + str(_state_chart.get_path()), _on_settings_updated)

func _unregister_settings_updates():
	# print("Unregistering settings updates for ", _state_chart.get_path())
	if not _state_chart.is_inside_tree():
		return

	EngineDebugger.unregister_message_capture(DebuggerMessage.SETTINGS_UPDATED_MESSAGE + str(_state_chart.get_path()))

func _on_settings_updated(key:String, data:Array) -> bool:
	_ignore_events = data[0]
	_ignore_transitions = data[1]
	# print("New settings for " ,  _state_chart.get_path(), ": ignore_events=", _ignore_events, ", ignore_transitions=", _ignore_transitions)
	return true


## Connects all signals from the currently processing state chart
func _prepare():
	_state_chart.event_received.connect(_on_event_received)

	# find all state nodes below the state chart and connect their signals
	for child in _state_chart.get_children():
		if child is StateChartState:
			_prepare_state(child)


func _prepare_state(state:StateChartState):
	state.state_entered.connect(_on_state_entered.bind(state))
	state.state_exited.connect(_on_state_exited.bind(state))
	state.transition_pending.connect(_on_transition_pending.bind(state))

	# send initial state
	DebuggerMessage.state_updated(_state_chart, state)

	# recurse into children
	for child in state.get_children():
		if child is StateChartState:
			_prepare_state(child)
		if child is Transition:
			child.taken.connect(_on_transition_taken.bind(state, child))


func _notification(what):
	match(what):
		Node.NOTIFICATION_ENTER_TREE:
			DebuggerMessage.state_chart_added(_state_chart)
			_register_settings_updates()
		Node.NOTIFICATION_UNPARENTED:
			DebuggerMessage.state_chart_removed(_state_chart)
			_unregister_settings_updates()
				


func _on_transition_taken(source:StateChartState, transition:Transition):
	if _ignore_transitions:
		return
	DebuggerMessage.transition_taken(_state_chart, source, transition)


func _on_event_received(event:StringName):
	if _ignore_events:
		return
	DebuggerMessage.event_received(_state_chart, event)
	
func _on_state_entered(state:StateChartState):
	DebuggerMessage.state_entered(_state_chart, state)		

func _on_state_exited(state:StateChartState):
	DebuggerMessage.state_exited(_state_chart, state)

func _on_transition_pending(num1, remaining, state:StateChartState):
	DebuggerMessage.transition_pending(_state_chart, state, state._pending_transition, remaining)
		

