extends StateChartTestBase

# Checks that we can do delayed transitions within a compound state
func test_delayed_transition_works():
	var root := compound_state("root")
	
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	transition(a, b, "some_event", "1.0")
	
	await finish_setup()
	
	assert_active(a)	

	# when i send the event
	send_event("some_event")

	# then the transition should not happen immediately, so a should still be active
	assert_active(a)
	
	await wait_seconds(1.1, "wait for the transition to happen")
	
	# then the transition should have happened, so b should be active
	assert_active(b)
	assert_inactive(a)
