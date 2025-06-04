extends StateChartTestBase


func test_basic_save():
	var root := compound_state("root")
	root.name = "root"
	var a := atomic_state("a", root)
	a.name = "a" 
	var b := atomic_state("b", root)
	b.name = "b"

	transition(a, b, "to_b")
	await finish_setup()

	_chart.name = "state_chart"
	_chart.add_child(root)
	
	# Convert the state chart to a Dictionary
	var save_dict: Dictionary = _chart.export_to_dict()

	var expected_save_dict := Dictionary({
		"name": "state_chart",
		"queued_events": Array([]),
		"property_change_pending": false,
		"state_change_pending": false,
		"locked_down": false,
		"queued_transitions": Array([]),
		"transitions_processing_active": false,
		"states": Dictionary({
			"name": "root",
			"state_class": "CompoundState",
			"active": true,
			"pending_transition_name": "",
			"pending_transition_remaining_delay": 0.0,
			"pending_transition_initial_delay": 0.0,
			"children": Array([
				Dictionary({
					"name": "a",
					"state_class": "AtomicState",
					"active": true,
					"pending_transition_name": "",
					"pending_transition_remaining_delay": 0.0,
					"pending_transition_initial_delay": 0.0,
					"children": Array([])
				}),
				Dictionary({
					"name": "b",
					"state_class": "AtomicState",
					"active": false,
					"pending_transition_name": "",
					"pending_transition_remaining_delay": 0.0,
					"pending_transition_initial_delay": 0.0,
					"children": Array([])
				})
			])
		})
	})
	print("Save Dict:")
	print(JSON.stringify(save_dict, "\t"))
	print("Expected Save Dict:")
	print(JSON.stringify(expected_save_dict, "\t"))
	assert_eq_deep(save_dict, expected_save_dict)


func test_save_with_history():
	var root := compound_state("root")
	root.name = "root"
	var a := compound_state("a", root)
	var a1 := atomic_state("a1", a)
	var a2 := atomic_state("a2", a)
	var h := history_state("h", a, a1)
	
	transition(a1, a2, "to_a2")

	var b := atomic_state("b", root)
	transition(a, b, "exit_a")	
	transition(b, h, "return_to_a")
	await finish_setup()

	_chart.name = "state_chart"
	_chart.add_child(root)
	
	# Convert the state chart to a Dictionary
	var save_dict: Dictionary = _chart.export_to_dict()

	var expected_save_dict := Dictionary({
		"name": "state_chart",
		"queued_events": Array([]),
		"property_change_pending": false,
		"state_change_pending": false,
		"locked_down": false,
		"queued_transitions": Array([]),
		"transitions_processing_active": false,
		"states": Dictionary({
			"name": "root",
			"state_class": "CompoundState",
			"active": true,
			"pending_transition_name": "",
			"pending_transition_remaining_delay": 0.0,
			"pending_transition_initial_delay": 0.0,
			"children": Array([
				Dictionary({
					"name": "a",
					"state_class": "CompoundState",
					"active": true,
					"pending_transition_name": "",
					"pending_transition_remaining_delay": 0.0,
					"pending_transition_initial_delay": 0.0,
					"children": Array([
						Dictionary({
							"name": "a1",
							"state_class": "AtomicState",
							"active": true,
							"pending_transition_name": "",
							"pending_transition_remaining_delay": 0.0,
							"pending_transition_initial_delay": 0.0,
							"children": Array([])
						}),
						Dictionary({
							"name": "a2",
							"state_class": "AtomicState",
							"active": false,
							"pending_transition_name": "",
							"pending_transition_remaining_delay": 0.0,
							"pending_transition_initial_delay": 0.0,
							"children": Array([])
						}),
						Dictionary({
							"name": "h",
							"state_class": "HistoryState",
							"active": false,
							"pending_transition_name": "",
							"pending_transition_remaining_delay": 0.0,
							"pending_transition_initial_delay": 0.0,
							"children": Array([]),
							"history": Dictionary()
						}),
					])
				}),
				Dictionary({
					"name": "b",
					"state_class": "AtomicState",
					"active": false,
					"pending_transition_name": "",
					"pending_transition_remaining_delay": 0.0,
					"pending_transition_initial_delay": 0.0,
					"children": Array([])
				})
			])
		})
	})
	# print("Save Dict:")
	# print(JSON.stringify(save_dict, "\t"))
	# print("Expected Save Dict:")
	# print(JSON.stringify(expected_save_dict, "\t"))
	assert_eq_deep(save_dict, expected_save_dict)

	send_event("exit_a")
	# b is now active and the history state should have a record of a1 as the last active state
	expected_save_dict["states"]["children"][0]["active"] = false # a is now inactive
	expected_save_dict["states"]["children"][0]["children"][0]["active"] = false # a1 is now inactive
	expected_save_dict["states"]["children"][1]["active"] = true # b is now active

	expected_save_dict["states"]["children"][0]["children"][2]["history"] = Dictionary({ 
		# the above refers to the node: states.children.a.children.h.history
		"child_states": {
			"a": {
				"child_states": {
					"a1": {
						"child_states": {},
						"history": {},
						"pending_transition_initial_delay": 0.0,
						"pending_transition_name": "",
						"pending_transition_remaining_delay": 0.0
					},
					"h": {
						"child_states": {},
						"history": {},
						"pending_transition_initial_delay": 0.0,
						"pending_transition_name": "",
						"pending_transition_remaining_delay": 0.0
					}		
				},
				"history": {},
				"pending_transition_initial_delay": 0.0,
				"pending_transition_name": "",
				"pending_transition_remaining_delay": 0.0
			}
		},
		"history": {},
		"pending_transition_initial_delay": 0.0,
		"pending_transition_name": "",
		"pending_transition_remaining_delay": 0.0
	})

	save_dict = _chart.export_to_dict()
	print("Save Dict:")
	print(JSON.stringify(save_dict, "\t"))
	print("Expected Save Dict:")
	print(JSON.stringify(expected_save_dict, "\t"))
	assert_eq_deep(save_dict, expected_save_dict)

 	# when i send a transition to return to a, then the history state should
	# remember that a1 was the last active state, so a1 should be active
	
	send_event("return_to_a")
	
	assert_active(a1)
	assert_inactive(b)
	
	# when i send a transition to a2, then a2 should be active
	send_event("to_a2")
	
	assert_active(a2)
	assert_inactive(a1)
	
	# when i send a transition to exit a
	send_event("exit_a")
	
	# then b should be active
	assert_active(b)
	
	# when i send a transition to return to a, then a2 should be active
	send_event("return_to_a")
	
	assert_active(a2)
	assert_inactive(a1)
	assert_inactive(b)

	save_dict = _chart.export_to_dict()
	print("Save Dict:")
	print(JSON.stringify(save_dict, "\t"))
	print("Expected Save Dict:")
	print(JSON.stringify(expected_save_dict, "\t"))
	# assert_eq_deep(save_dict, expected_save_dict)	




# Load the state chart from the Dictionary

# Verify that the state chart is in the same state as it was before

# Verify that the state chart isn't sending alerts

# Verify that the state chart is sending events

# Activate the loaded state chart + modify it
# Verify that the state chart is sending alerts
# Verify that the state chart is sending messages

# Save the state chart to a file

# Load the state chart from the file

# Verify that the state chart is in the same state as it was before

# Verify that the state chart isn't sending alerts
