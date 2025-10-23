extends StateChartTestBase


func test_simple_serialization():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	
	transition(a, b, "to_b")

	await finish_setup()
	assert_active(a)

	# when i save the state chart
	var saved:SerializedStateChart = StateChartSerializer.serialize(_chart)
	
	# and then enter b
	send_event("to_b")
	assert_active(b)
	
	# and then restore the state chart
	var errors := StateChartSerializer.deserialize(saved, _chart)
	
	# then a is active again
	assert_active(a)
	# and we have no errors
	assert_eq(errors.size(), 0)
	

func test_simple_serialization_restore_on_new_chart():
	# Build and serialize the first chart where 'a' is initially active
	var root1 := compound_state("root")
	var a1 := atomic_state("a", root1)
	var b1 := atomic_state("b", root1)
	transition(a1, b1, "to_b")
	await finish_setup()
	assert_active(a1)
	var saved: SerializedStateChart = StateChartSerializer.serialize(_chart)

	# Move the original chart to 'b' (not strictly needed for this test, but mirrors the original test)
	send_event("to_b")
	assert_active(b1)

	# Now create a completely new StateChart with the same structure
	var new_chart := chart("new")
	var new_root := compound_state("root", new_chart)
	var new_a := atomic_state("a", new_root)
	var new_b := atomic_state("b", new_root)
	transition(new_a, new_b, "to_b")
	
	await finish_setup(new_chart)

	# Verify the new chart can transition independently
	assert_active(new_a)
	new_chart.send_event("to_b")
	assert_active(new_b)

	# Restore the saved state into the completely new chart
	var new_errors := StateChartSerializer.deserialize(saved, new_chart)

	# After restoration, 'a' should be active again on the new chart and there should be no errors
	assert_active(new_a)
	assert_eq(new_errors.size(), 0)
	

func test_serialization_with_history():
	var root := compound_state("root")
	var a := compound_state("a", root)
	var a1 := atomic_state("a1", a)
	var a2 := atomic_state("a2", a)
	var b := atomic_state("b", root)
	var h := history_state("h", a, a1)

	transition(a1, a2, "to_a2")
	transition(a, b, "to_b")	
	transition(b, h, "to_h")

	await finish_setup()
	assert_active(a)
	assert_active(a1)
	assert_inactive(b)
	
	# send an event so we go to a2
	send_event("to_a2")
	assert_active(a2)
	assert_inactive(a1)

	# now we enter b to prepare our history state. the when we go to the 
	# history state, the state chart should activate a2 now, because that was
	# last active when we left a
	send_event("to_b")
	assert_active(b)
	assert_inactive(a)
	
	# WHEN i save the state chart.
	var saved:SerializedStateChart = StateChartSerializer.serialize(_chart)

	# and use the state chart's history to go back to a
	send_event("to_h")
	assert_active(a)
	assert_active(a2)
	
	# AND i then restore the state chart
	var errors := StateChartSerializer.deserialize(saved, _chart)
	
	# THEN b should be active again
	assert_active(b)
	assert_inactive(a)
	assert_inactive(a1)
	
	# AND we have no errors
	assert_eq(errors.size(), 0)
	
	# AND the history state should still remember a2 as the last active state
	send_event("to_h")
	assert_active(a)
	assert_active(a2)
	

func test_serialization_with_history_restore_on_new_chart():
	# Build and serialize the first chart where 'a' has a history that points to a2
	var root1 := compound_state("root")
	var a := compound_state("a", root1)
	var a1 := atomic_state("a1", a)
	var a2 := atomic_state("a2", a)
	var b1 := atomic_state("b", root1)
	var h1 := history_state("h", a, a1)
	transition(a1, a2, "to_a2")
	transition(a, b1, "to_b")
	transition(b1, h1, "to_h")
	
	await finish_setup()
	
	# a/a1 should be active initially
	assert_active(a)
	assert_active(a1)
	# move to a2, then to b so history remembers a2
	send_event("to_a2")
	assert_active(a2)
	send_event("to_b")
	assert_active(b1)
	
	# WHEN: I save serialized state (with history saved inside 'h')
	var saved: SerializedStateChart = StateChartSerializer.serialize(_chart)

	# AND: i create a completely new chart with the same structure using helpers
	var new_chart := chart("new")
	var root2 := compound_state("root", new_chart)
	var na := compound_state("a", root2)
	var na1 := atomic_state("a1", na)
	var na2 := atomic_state("a2", na)
	var nb := atomic_state("b", root2)
	var nh := history_state("h", na, na1)
	transition(na1, na2, "to_a2")
	transition(na, nb, "to_b")
	transition(nb, nh, "to_h")
	await finish_setup(new_chart)
	
	# AND: the new chart is in its initial state
	assert_active(na)
	assert_active(na1)

	# AND: I restore the saved state into the new chart
	var new_errors := StateChartSerializer.deserialize(saved, new_chart)
	# THEN: b should be active in the new chart
	assert_active(nb)
	assert_inactive(na)
	assert_inactive(na1)
	
	# AND: there should be no errors
	assert_eq(new_errors.size(), 0)

	# AND: the history state should still remember a2 as the last active state
	new_chart.send_event("to_h")
	assert_active(na)
	assert_active(na2)
	

func test_frozen_state_chart():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	var to_b := transition(a, b, "to_b")
	transition(b, a, "to_a")
	await finish_setup()

	_chart.name = "state_chart"
	watch_signals(_chart)
	watch_signals(a)
	watch_signals(b)

	# verify starting state
	assert_active(a)
	assert_inactive(b)

	# ensure that the chart works as expected when not frozen
	send_event("to_b")
	assert_active(b)
	assert_inactive(a)
	assert_signal_emitted(_chart, "event_received")
	assert_signal_emitted(a, "state_exited")
	assert_signal_emitted(a, "event_received")
	assert_signal_emitted(b, "state_entered")
	assert_eq(_chart._queued_events.size(), 0)
	assert_eq(_chart._queued_transitions.size(), 0)

	# return back to a, so now we can try the same with a frozen chart
	send_event("to_a")

	clear_signal_watcher()
	watch_signals(_chart)
	watch_signals(a)
	watch_signals(b)

	# verify starting state
	assert_active(a)
	assert_inactive(b)

	# when processing a transition while frozen
	# the state chart should not send any alerts
	# or modify the state chart
	_chart.freeze()

	# verify that the state chart has not changed
	# it should also not enqueue any new events or transitions
	send_event("to_b")
	assert_active(a)
	assert_inactive(b)
	assert_signal_not_emitted(_chart, "event_received")
	assert_signal_not_emitted(b, "state_exited")
	assert_signal_not_emitted(a, "event_received")
	assert_signal_not_emitted(a, "state_entered")
	assert_signal_not_emitted(b, "event_received")
	assert_signal_not_emitted(b, "state_entered")
	assert_eq(_chart._queued_events.size(), 0)
	assert_eq(_chart._queued_transitions.size(), 0)
	
	
	# verify that trying to take a transition manually also does not work
	# when the chart is frozen.
	to_b.take()
	assert_active(a)
	assert_inactive(b)
	assert_signal_not_emitted(_chart, "event_received")
	assert_signal_not_emitted(b, "state_exited")
	assert_signal_not_emitted(a, "event_received")
	assert_signal_not_emitted(a, "state_entered")
	assert_signal_not_emitted(b, "event_received")
	assert_signal_not_emitted(b, "state_entered")
	assert_eq(_chart._queued_events.size(), 0)
	assert_eq(_chart._queued_transitions.size(), 0)
	
	

func test_version_check_on_deserialization():
	# Create a simple state chart
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	transition(a, b, "to_b")	
	await finish_setup()

	_chart.name = "state_chart"

	# Serialize the state chart
	var serialized_chart:SerializedStateChart = StateChartSerializer.serialize(_chart)

	# Verify the initial version is correct
	assert_eq(serialized_chart.version, 1)

	# Modify the version to an unsupported value
	serialized_chart.version = 999

	# Attempt to deserialize with the incorrect version
	var error_messages := StateChartSerializer.deserialize(serialized_chart, _chart)

	# Verify that deserialization failed with the appropriate error message
	assert_eq(error_messages.size(), 1)

	if error_messages.size() > 0: 
		assert_true(error_messages[0].contains("Unsupported serialized state chart version"))


func test_state_name_check_on_deserialization():
	# Create a simple state chart
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	transition(a, b, "to_b")	
	await finish_setup()

	_chart.name = "state_chart"

	# Serialize the state chart
	var serialized_chart:SerializedStateChart = StateChartSerializer.serialize(_chart)

	# Modify the state name in the serialized state
	serialized_chart.state.name = "modified_root"

	# Attempt to deserialize with the modified state name
	var error_messages := StateChartSerializer.deserialize(serialized_chart, _chart)

	# Verify that deserialization failed with the appropriate error message
	assert_eq(error_messages.size(), 1)

	if error_messages.size() > 0: 
		assert_true(error_messages[0].contains("State name mismatch"))
		assert_true(error_messages[0].contains("root"))
		assert_true(error_messages[0].contains("modified_root"))


func test_state_type_check_on_deserialization():
	# Create a simple state chart
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	transition(a, b, "to_b")	
	await finish_setup()

	_chart.name = "state_chart"

	# Serialize the state chart
	var serialized_chart:SerializedStateChart = StateChartSerializer.serialize(_chart)

	# Modify the state type in the serialized state
	# 1 is CompoundState, 0 is AtomicState
	serialized_chart.state.children[0].state_type = 1  # Change from AtomicState to CompoundState

	# Attempt to deserialize with the modified state type
	var error_messages := StateChartSerializer.deserialize(serialized_chart, _chart)

	# Verify that deserialization failed with the appropriate error message
	assert_eq(error_messages.size(), 1)

	if error_messages.size() > 0: 
		assert_true(error_messages[0].contains("State type mismatch"))
		assert_true(error_messages[0].contains("0"))  # AtomicState
		assert_true(error_messages[0].contains("1"))  # CompoundState


func test_pending_transition_name_check_on_deserialization():
	# Create a simple state chart
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	transition(a, b, "to_b")	
	await finish_setup()

	_chart.name = "state_chart"

	# Serialize the state chart
	var serialized_chart:SerializedStateChart = StateChartSerializer.serialize(_chart)

	# Modify the pending transition name in the serialized state
	serialized_chart.state.children[0].pending_transition_name = "non_existent_transition"

	# Attempt to deserialize with the modified pending transition name
	var error_messages := StateChartSerializer.deserialize(serialized_chart, _chart)

	# Verify that deserialization failed with the appropriate error message
	assert_eq(error_messages.size(), 1)

	if error_messages.size() > 0: 
		assert_true(error_messages[0].contains("Pending transition"))
		assert_true(error_messages[0].contains("not found"))
		assert_true(error_messages[0].contains("non_existent_transition"))


func test_additional_state_in_serialized_state():
	# Create a simple state chart
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	transition(a, b, "to_b")	
	await finish_setup()

	_chart.name = "state_chart"

	# Serialize the state chart
	var serialized_chart:SerializedStateChart = StateChartSerializer.serialize(_chart)

	# Add an additional state to the serialized state that doesn't exist in the tree
	var additional_state := SerializedStateChartState.new()
	additional_state.name = "non_existent_state"
	additional_state.state_type = 0  # AtomicState
	additional_state.active = false
	serialized_chart.state.children.append(additional_state)

	# Attempt to deserialize with the additional state
	var error_messages := StateChartSerializer.deserialize(serialized_chart, _chart)

	# Verify that deserialization failed with the appropriate error message
	assert_eq(error_messages.size(), 1)

	if error_messages.size() > 0: 
		assert_true(error_messages[0].contains("Serialized state has child state"))
		assert_true(error_messages[0].contains("non_existent_state"))
		assert_true(error_messages[0].contains("no such state exists in the tree"))


func test_fewer_states_in_serialized_state():
	# Create a simple state chart with multiple states
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	var c := atomic_state("c", root)
	transition(a, b, "to_b")
	transition(b, c, "to_c")
	await finish_setup()

	_chart.name = "state_chart"

	# Serialize the state chart
	var serialized_chart:SerializedStateChart = StateChartSerializer.serialize(_chart)

	# Remove one of the states from the serialized state
	# Find and remove state 'c' from the serialized children
	for i in range(serialized_chart.state.children.size()):
		if serialized_chart.state.children[i].name == "c":
			serialized_chart.state.children.remove_at(i)
			break

	# Attempt to deserialize with fewer states
	var error_messages := StateChartSerializer.deserialize(serialized_chart, _chart)

	# Verify that deserialization failed with the appropriate error message
	assert_eq(error_messages.size(), 1)

	if error_messages.size() > 0:
		assert_true(error_messages[0].contains("Tree has child state"))
		assert_true(error_messages[0].contains("c"))
		assert_true(error_messages[0].contains("no such child state exists in the serialized state"))

#----------------------------------------------------------------------------------------------------------
# helpers for printing serialized state charts for debugging
#----------------------------------------------------------------------------------------------------------

func print_serialized_chart_state(serialized: SerializedStateChart) -> void:
	var lines: Array[String] = []
	if is_instance_valid(serialized):
		lines.append("SerializedStateChart: %s" % [serialized.name])
		if is_instance_valid(serialized.state):
			_append_serialized_state_lines(serialized.state, "  ", lines)
		else:
			lines.append("  <no state>")
	else:
		lines.append("<no SerializedStateChart>")
	for line in lines:
		print(line)

func _append_serialized_state_lines(state: SerializedStateChartState, indent: String, lines: Array[String]) -> void:
	if not is_instance_valid(state):
		return
	var active_text: String = "active" if state.active else "inactive"
	var type_letter := _serialized_state_type_letter(state.state_type)
	lines.append("%s- [%s] %s (%s)" % [indent, type_letter, state.name, active_text])
	if not state.pending_transition_name.is_empty():
		lines.append("%s  -> %s (%.2f)" % [indent, state.pending_transition_name, state.pending_transition_remaining_delay])
	if state.state_type == 3 and is_instance_valid(state.history):
		var paths := _collect_saved_state_paths(state.history, "")
		if paths.size() > 0:
					lines.append("%s  history: %s" % [indent, ", ".join(paths)])
	for child in state.children:
					_append_serialized_state_lines(child, indent + "  ", lines)

func _serialized_state_type_letter(state_type: int) -> String:
	match state_type:
		0:
			return "A"
		1:
			return "C"
		2:
			return "P"
		3:
			return "H"
		_:
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

