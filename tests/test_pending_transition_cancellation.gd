extends StateChartTestBase


# Verifies that a pending transition is cancelled when the source state is exited.
func test_pending_transition_cancellation():
	var root := compound_state("root")
	
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	var c := atomic_state("c", root)
	
	# run a pending transition from a to b, directly when a is entered
	transition(a, b, "", "2.0")
	
	# set up a transition from a to c
	transition(a, c, "to_c")
	
	await finish_setup()
	
	# right now, a should be active
	assert_active(a)
	
	# wait one second, so so that the transition from a to b is still pending
	await wait_seconds(1.0, "waiting with pending transition")
	
	# send the event that triggers the transition from a to c
	send_event("to_c")
	
	# now, c should be active, effectively cancelling the pending transition to b
	assert_active(c)
	
