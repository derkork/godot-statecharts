extends StateChartTestBase

func test_transition_taken_signal():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	
	transition(a, b, "to_b", "1")
	await finish_setup()

	watch_signals(a)
	assert_active(a)

	# when i send the event to move to b
	send_event("to_b")
	
	# and wait 0.5 seconds
	await wait_seconds(0.5, "waiting for pending transition")
	
	# then a should have emitted the "transition_pending" signal
	assert_signal_emitted(a, "transition_pending")
	
	var parameters:Array = get_signal_parameters(a, "transition_pending")
	
	# and the parameters should be correct
	# the first parameter should match the initial length of the transition
	assert_eq(parameters[0], 1.0)
	
	# and the second one should be the remaining time, which should be somewhere around 0.5
	assert_between(parameters[1], 0.4, 0.6)
