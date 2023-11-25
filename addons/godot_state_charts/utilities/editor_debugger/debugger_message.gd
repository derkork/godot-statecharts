class_name StateChartDebuggerMessage

const MESSAGE_PREFIX = "godot_state_charts"
const STATE_CHART_ADDED_MESSAGE = MESSAGE_PREFIX + ":state_chart_added"
const STATE_CHART_REMOVED_MESSAGE = MESSAGE_PREFIX + ":state_chart_removed"
const STATE_UPDATED_MESSAGE = MESSAGE_PREFIX + ":state_updated"
const STATE_ENTERED_MESSAGE = MESSAGE_PREFIX + ":state_entered"
const STATE_EXITED_MESSAGE = MESSAGE_PREFIX + ":state_exited"
const TRANSITION_FIRED_MESSAGE = MESSAGE_PREFIX + ":transition_fired"

const DebuggerStateInfo = preload("debugger_state_info.gd")

## Whether we can currently send debugger messages.
static func _can_send() -> bool:
	return not Engine.is_editor_hint() and OS.has_feature("editor")
	
	
## Sends a state_chart_added message.
static func state_chart_added(chart:StateChart):
	if not _can_send():
		return
		
	EngineDebugger.send_message(STATE_CHART_ADDED_MESSAGE, [chart.get_path()])
		
## Sends a state_chart_removed message.		
static func state_chart_removed(chart:StateChart):
	if not _can_send():
		return
		
	EngineDebugger.send_message(STATE_CHART_REMOVED_MESSAGE, [chart.get_path()])
		
		
## Sends a state_updated message
static func state_updated(state:State):
	if not _can_send():
		return

	var transition_path = NodePath()
	if is_instance_valid(state._pending_transition):
		transition_path = state._pending_transition.get_path()
		
	EngineDebugger.send_message(STATE_UPDATED_MESSAGE, DebuggerStateInfo.make_array( \
		state._chart.get_path(), \
		state.get_path(), \
		state.active, \
		is_instance_valid(state._pending_transition), \
		transition_path, \
		state._pending_transition_time, \
		state)
	)
	

## Sends a state_entered message
static func state_entered(state:State):
	if not _can_send():
		return
		
	EngineDebugger.send_message(STATE_ENTERED_MESSAGE,[state._chart.get_path(), state.get_path()])

## Sends a state_exited message
static func state_exited(state:State):
	if not _can_send():
		return
		
	EngineDebugger.send_message(STATE_EXITED_MESSAGE,[state._chart.get_path(), state.get_path()])

## Sends a transition_fired message
static func transition_fired(transition:Transition):
	if not _can_send():
		return
		
	EngineDebugger.send_message(TRANSITION_FIRED_MESSAGE,[transition._chart.get_path(), transition.get_path()])