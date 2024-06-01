extends StateChartTestBase

# Tests that if we have parallel states and send an event 
# that has transitions in both sub-states, all these transitions happend

func test_parallel_transition():

	var root := parallel_state("root")

	# make one parallel branch
	var a := compound_state("a", root)
	var a1 := atomic_state("a1", a)
	var a2 := atomic_state("a2", a)

	transition(a1, a2, "some_event")

	# make another parallel branch
	var b := compound_state("b", root)
	var b1 := atomic_state("b1", b)
	var b2 := atomic_state("b2", b)

	transition(b1, b2, "some_event")

	await finish_setup()
	
	# both parallel branches should be active
	assert_active(a1)
	assert_active(b1)

	# when i send the event, both a1 and b1 should transition to a2 and b2
	send_event("some_event")

	assert_active(a2)
	assert_active(b2)
	
	assert_inactive(a1)
	assert_inactive(b1)
	
	
	
