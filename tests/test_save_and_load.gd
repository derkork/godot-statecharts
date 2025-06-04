extends StateChartTestBase


func test_export_to_resource():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)

	await finish_setup()

	_chart.name = "state_chart"

	var resource:SerializedStateChart = _chart.export_to_resource()

	# SerializedStateChart
	assert_eq(resource.name, "state_chart")
	assert_eq(resource.queued_events, [])
	assert_eq(resource.property_change_pending, false)
	assert_eq(resource.state_change_pending, false)
	assert_eq(resource.locked_down, false)
	assert_eq(resource.queued_transitions, [])
	assert_eq(resource.transitions_processing_active, false)

	# SerializedStateChartState children
	assert_eq(resource.state.name, "root")
	assert_eq(resource.state.state_class, "CompoundState")
	assert_eq(resource.state.active, true)
	
	assert_eq(resource.state.children.size(), 2)
	assert_eq(resource.state.children[0].name, "a")
	assert_eq(resource.state.children[0].state_class, "AtomicState")
	assert_eq(resource.state.children[0].active, true)
	assert_eq(resource.state.children[1].name, "b")
	assert_eq(resource.state.children[1].state_class, "AtomicState")
	assert_eq(resource.state.children[1].active, false)


func test_export_to_resource_with_history():
	var root := compound_state("root")
	var a := compound_state("a", root)
	var a1 := atomic_state("a1", a)
	var a2 := atomic_state("a2", a)
	var b := atomic_state("b", root)
	var h := history_state("h", a, a1)
	
	transition(a1, a2, "to_a2")
	transition(a, b, "exit_a")	
	transition(b, h, "return_to_a")

	await finish_setup()

	_chart.name = "state_chart"
	
	var resource:SerializedStateChart = _chart.export_to_resource()

	# Spot-check to ensure that the resource is set up as expected
	assert_eq(resource.name, "state_chart")
	assert_eq(resource.state.name, "root")
	assert_eq(resource.state.active, true)
	assert_eq(resource.state.children.size(), 2)
	assert_eq(resource.state.children[0].children[0].name, "a1")
	assert_eq(resource.state.children[0].children[0].active, true)
	assert_eq(resource.state.children[0].children[2].name, "h")
	assert_eq(resource.state.children[0].children[2].active, false)

	# when i send a transition to exit a, then a should be inactive and b should be active
	# there should also be a record of a1 as the last active state in the history state
	send_event("exit_a")

	resource = _chart.export_to_resource()

	assert_eq(resource.state.children[0].active, false) # a is now inactive
	assert_eq(resource.state.children[0].children[0].active, false) # a1 is now inactive
	assert_eq(resource.state.children[0].children[2].name, "h")
	assert_eq(resource.state.children[0].children[2].active, false)
	assert_eq(resource.state.children[1].active, true) # b is now active

	# examining the Resource for the Serialized History State:
	assert_eq(resource.state.children[0].children[2].history.child_states.size(), 1)
	assert_eq(resource.state.children[0].children[2].history.child_states["a"].child_states.size(), 2)
	assert_has(resource.state.children[0].children[2].history.child_states["a"].child_states, "a1")
	assert_has(resource.state.children[0].children[2].history.child_states["a"].child_states, "h")

 	# when i send a transition to return to a, then the history state should
	# remember that a1 was the last active state, so a1 should be active
	
	send_event("return_to_a")

	resource = _chart.export_to_resource()

	assert_eq(resource.state.children[0].active, true) # a is now active
	assert_eq(resource.state.children[0].children[0].active, true) # a1 is now active
	assert_eq(resource.state.children[0].children[2].name, "h")
	assert_eq(resource.state.children[0].children[2].active, false)
	assert_eq(resource.state.children[1].active, false) # b is now inactive
	
	# the history state history should now be null again.
	assert_eq(resource.state.children[0].children[2].history, null)

	# when i send a transition to a2 and then out of a
	send_event("to_a2")
	send_event("exit_a")

	resource = _chart.export_to_resource()
	
	# then b should be active
	assert_eq(resource.state.children[1].active, true) # b is now active

	# history should now have a2 as the last active state
	assert_eq(resource.state.children[0].children[2].history.child_states.size(), 1)
	assert_eq(resource.state.children[0].children[2].history.child_states["a"].child_states.size(), 2)
	assert_has(resource.state.children[0].children[2].history.child_states["a"].child_states, "a2")
	assert_has(resource.state.children[0].children[2].history.child_states["a"].child_states, "h")


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
