extends StateChartTestBase

func test_transition_taken_signal():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	var c := atomic_state("c", root)
	
	var t := transition(a, b, "to_b")
	var t2 := transition(a, c, "to_c")
	
	await finish_setup()
	
	watch_signals(t)
	watch_signals(t2)
	
	# when i trigger a transition
	send_event("to_b")
	
	# then the transition's "taken" signal should be emitted
	assert_signal_emitted(t, "taken")
	
	# and the other transition's "taken" signal should not be emitted
	assert_signal_not_emitted(t2, "taken")
