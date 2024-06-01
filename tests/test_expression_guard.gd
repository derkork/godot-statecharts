extends StateChartTestBase

func test_expression_guard():
	var root := compound_state("root")
	
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	
	transition(a, b, "to_b", "0", expression_guard("foo > bar"))
	await finish_setup()
	
	assert_active(a) # initial state
	
	set_expression_property("foo", 0)
	set_expression_property("bar", 1)
	
	# when i send the event, the transition should not be taken
	send_event("to_b")
	assert_active(a)
	assert_inactive(b)
	
	
	set_expression_property("foo", 2)
	
	# when i send the event, the transition should be taken
	send_event("to_b")
	
	assert_inactive(a)
	assert_active(b)
