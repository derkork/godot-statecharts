extends StateChartTestBase

func test_state_is_active_guard():
	var root := parallel_state("root")
	
	var a := compound_state("a", root)
	var a1 := atomic_state("a1", a)
	var a2 := atomic_state("a2", a)
	
	var b := compound_state("b", root)
	var b1 := atomic_state("b1", b)
	var b2 := atomic_state("b2", b)
	
	transition(a1, a2, "to_a2")
	transition( b1, b2, "to_b2", "0", state_is_active_guard(a2))
	
	await finish_setup()
	
	assert_active(a1)
	assert_active(b1)
	
	# when i send the transition to activate b2
	send_event("to_b2")
	
	# then b2 should not be active, because the guard is false
	assert_active(b1)
	assert_inactive(b2)
	
	# when i send the transition to activate a2
	send_event("to_a2")
	
	# then a2 should be active
	assert_active(a2)
	
	# when i send the transition to activate b2 again
	send_event("to_b2")
	
	# then b2 should be active because this time the guard allowed it.
	assert_active(b2)
	
