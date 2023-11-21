extends EditorDebuggerPlugin

var sessions:Dictionary = {}

var debugger_ui_scene:PackedScene = preload("editor_debugger.tscn")

func _has_capture(prefix):
	return prefix == StateChartDebuggerMessage.MESSAGE_PREFIX

func _capture(message, data, session_id):
	# print(session_id , ": " , message, " -> " , data)
	var ui = get_session(session_id).get_meta("__state_charts_debugger_ui")
	if message == StateChartDebuggerMessage.STATE_CHART_ADDED_MESSAGE:
		ui.add_chart(data[0])

	if message == StateChartDebuggerMessage.STATE_CHART_REMOVED_MESSAGE:
		ui.remove_chart(data[0])
		
	if message == StateChartDebuggerMessage.STATE_UPDATED_MESSAGE:
		ui.update_state(data)
	
	return true

func _setup_session(session_id):
	# get the session
	var session = get_session(session_id)
	# Add a new tab in the debugger session UI containing a label.
	var debugger_ui = debugger_ui_scene.instantiate()
	# add the session tab
	session.add_session_tab(debugger_ui)
	session.stopped.connect(debugger_ui.clear)
	session.set_meta("__state_charts_debugger_ui", debugger_ui)
