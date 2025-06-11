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


func test_basic_load_from_resource():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	var t := transition(a, b, "to_b")	

	watch_signals(a)
	watch_signals(b)

	await finish_setup()

	assert_true(a.is_processing())
	assert_true(a.is_physics_processing())

	########################################################################
	#### Part 1: verify starting state
	########################################################################
	assert_active(a)
	assert_inactive(b)

	# verify that the state chart is processing as expected
	await wait_frames(10, "Run for a little while.")
	
	assert_signal_emitted(a, "state_processing")
	assert_signal_emitted(a, "state_physics_processing")

	assert_signal_not_emitted(b, "state_processing")
	assert_signal_not_emitted(b, "state_physics_processing")

	########################################################################
	#### Part 2: export the state chart to a resource
	########################################################################
	var resource:SerializedStateChart = _chart.export_to_resource()	

	########################################################################
	#### Part 3: modify the state chart post-save
	########################################################################
	clear_signal_watcher()
	watch_signals(a)
	watch_signals(b)

	# modify the state chart
	send_event("to_b")

	# ensure that the state chart is in the expected state
	assert_active(b)
	assert_inactive(a)

	await wait_frames(10, "Run for a little while.")
		
	assert_true(b.is_processing())
	assert_true(b.is_physics_processing())
	
	assert_signal_emitted(b, "state_processing")
	assert_signal_emitted(b, "state_physics_processing")

	assert_signal_not_emitted(a, "state_processing")
	assert_signal_not_emitted(a, "state_physics_processing")

	########################################################################
	#### Part 4: load the state chart from the resource and verify that it's in
	#### the same state as when it was exported.
	########################################################################
	clear_signal_watcher()
	watch_signals(a)
	watch_signals(b)

	_chart.load_from_resource(resource)

	# ensure that the state chart is in the same state as when it was exported
	assert_active(a)
	assert_inactive(b)

	# Verify that the state chart didn't send any signals
	assert_signal_not_emitted(a, "state_processing")
	assert_signal_not_emitted(a, "state_physics_processing")
	assert_signal_not_emitted(b, "state_processing")
	assert_signal_not_emitted(b, "state_physics_processing")
	assert_signal_not_emitted(a, "state_entered")
	assert_signal_not_emitted(a, "state_exited")
	assert_signal_not_emitted(b, "state_entered")
	assert_signal_not_emitted(b, "state_exited")

	# Ensure that the state chart has resumed processing
	await wait_frames(10, "Run for a little while.")
		
	assert_true(a.is_processing())
	assert_true(a.is_physics_processing())
	
	assert_signal_emitted(a, "state_processing")
	assert_signal_emitted(a, "state_physics_processing")

	assert_signal_not_emitted(b, "state_processing")
	assert_signal_not_emitted(b, "state_physics_processing")

	########################################################################
	#### Part 5: Make sure signal processing and state changing work as expected
	########################################################################
	clear_signal_watcher()
	watch_signals(a)
	watch_signals(b)
	watch_signals(t)
	send_event("to_b")

	assert_signal_emitted(t, "taken")

	assert_active(b)
	assert_inactive(a)

	assert_signal_emitted(a, "state_exited")
	assert_signal_emitted(b, "state_entered")


func test_load_from_resource_with_pending_transition():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	transition(a, b, "to_b", "0.5")
	await finish_setup()

	# when i trigger the transition
	send_event("to_b")

	# then the transition should not be taken immediately
	await wait_seconds(0.2)
	assert_active(a)

	# export the state chart to a resource
	var resource:SerializedStateChart = _chart.export_to_resource()	

	# verify that the state chart is in the expected state
	# after an additional 0.5 seconds the transition should be taken
	await wait_seconds(0.5)
	assert_active(b)
	assert_inactive(a)

	# load the state chart from the resource
	_chart.load_from_resource(resource)

	# verify that the state chart has been reset
	assert_active(a)
	assert_inactive(b)

	# Verify that the count down still works
	await wait_seconds(0.2) # 0.2 pre-save + 0.2 post-load = 0.4 total delay
	assert_active(a)
	assert_inactive(b)

	await wait_seconds(0.2) # 0.2 post-load + 0.4 post-load = 0.6 total delay
	assert_active(b)
	assert_inactive(a)


func test_frozen_state_chart():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	transition(a, b, "to_b")	
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

	clear_signal_watcher()
	watch_signals(_chart)
	watch_signals(a)
	watch_signals(b)
	
	# verify starting state
	assert_active(b)
	assert_inactive(a)

	# when processing a transition while frozen
	# the state chart should not send any alerts
	# or modify the state chart
	_chart._frozen = true

	# verify that the state chart has not changed
	# it should also not enqueue any new events or transitions
	send_event("to_b")
	assert_active(b)
	assert_inactive(a)
	assert_signal_not_emitted(_chart, "event_received")
	assert_signal_not_emitted(b, "state_exited")
	assert_signal_not_emitted(a, "event_received")
	assert_signal_not_emitted(a, "state_entered")
	assert_signal_not_emitted(b, "event_received")
	assert_signal_not_emitted(b, "state_entered")
	assert_eq(_chart._queued_events.size(), 0)
	assert_eq(_chart._queued_transitions.size(), 0)
