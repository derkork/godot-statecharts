extends StateChartTestBase

# Checks that we can do simple transitions within a compound state
func test_simple_transition_works():
	var root := compound_state("root")
	
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	
	transition(a, b, "some_event")
	await finish_setup()
	
	assert_active(a)
	
	# when i send the event
	send_event("some_event")

	assert_active(b)
	assert_inactive(a)

