extends StateChartTestBase

# Tests that history states work as expected.
func test_history_state_simple():
	var root := compound_state("root")
	
	var a := compound_state("a", root)
	var a1 := atomic_state("a1", a)
	var a2 := atomic_state("a2", a)
	var h := history_state("h", a, a1)

	transition(a1, a2, "to_a2")
	
	var b := atomic_state("b", root)
	transition(a, b, "exit_a")	
	transition(b, h, "return_to_a")
	
	await finish_setup()
	
	# now a1 should be active, as it is the initial state
	assert_active(a1)
	
	# when i send a transition to exit a
	send_event("exit_a")
	
	# then b should be active
	assert_active(b)
	assert_inactive(a1)
	
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
	
	
	
	
	
	
