extends StateChartTestBase

func test_event_consumption():
	var root := compound_state("root")
	var a := compound_state("a", root)
	var b := compound_state("b", root)
	# add a transition from a to b reacting on the "switch" event
	var t1 := transition(a, b, "switch")	

	var a1 := atomic_state("a1", a)
	var a2 := atomic_state("a2", a)
	# add a transition from a1 to a2 reacting on the "switch" event
	var t2 := transition(a1, a2, "switch")
	
	await finish_setup()
	assert_active(a)
	assert_active(a1)
	
	watch_signals(t1)
	watch_signals(t2)
	
	# when i send the "switch" event...
	send_event("switch")
	
	# then
	# the transition from a1 to a2 should be taken, consuming the event
	assert_active(a)
	assert_active(a2)
	assert_inactive(a1)
	assert_inactive(b)
	
	# the transition t2 should have emitted a "taken" signal
	assert_signal_emitted(t2, "taken")
	
	# the transition t1 should not have emitted a "taken" signal
	assert_signal_not_emitted(t1, "taken")
