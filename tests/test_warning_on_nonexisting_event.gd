extends StateChartTestBase

func test_warning_on_nonexisting_event():
	var root = compound_state("root")
	var a = atomic_state("a", root)
	var b = atomic_state("b", root)
	transition(a, b, "some_event")
	transition(b, a, "some_event")
	await finish_setup()
	
	assert_active(a)

	# when i send the correct event, i move to state b
	send_event("some_event")
	assert_active(b)
	
	# when i send a wrong event, nothing happens
	send_event("narf")
	
	assert_active(b)
	
			
