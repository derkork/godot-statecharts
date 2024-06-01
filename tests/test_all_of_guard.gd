extends StateChartTestBase

func test_all_of_guard():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	
	transition(a, b, "to_b", "0", all_of_guard([expression_guard("foo == 1"), expression_guard("bar == 2")]))
	await finish_setup()
	
	# root state is active
	assert_active(a)
	
	set_expression_property("foo", 1)
	set_expression_property("bar", 0)
	
	# when i send the "to_b" event, then the transition should not be taken
	send_event("to_b")
	assert_active(a)

	set_expression_property("foo", 0)
	set_expression_property("bar", 2)
	
	# when i send the "to_b" event, then the transition should not be taken
	send_event("to_b")
	assert_active(a)
	
	set_expression_property("foo", 1)
	set_expression_property("bar", 2)
	
	# when i send the "to_b" event, then the transition should be taken
	send_event("to_b")
	assert_active(b)
	assert_inactive(a)
	
