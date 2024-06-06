extends StateChartTestBase

func test_parallel_state_event_handling():
	var root := parallel_state("root")
	
	var a := compound_state("a", root)
	var a1 := atomic_state("a1", a)
	var a2 := atomic_state("a2", a)
	
	var b := compound_state("b", root)
	var b1 := atomic_state("b1", b)
	var b2 := atomic_state("b2", b)
	
	transition(a1, a2, "to_a2")
	transition( b1, b2, "", "0", state_is_active_guard(a2))
	
	await finish_setup()
	
	assert_active(a1)
	assert_active(b1)
	
	# when i send an event to switch to a2, b1 should automatically switch to b2
	send_event("to_a2")
	
	assert_active(a2)
	# this only works because b2 is a child of b which is a parallel state, so b's transition
	# will be triggered even if a1 consumes the event
	assert_active(b2)
	

