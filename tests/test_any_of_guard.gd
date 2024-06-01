extends StateChartTestBase

func test_all_of_guard():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	
	transition(a, b, "to_b", "0", any_of_guard([expression_guard("foo == 1"), expression_guard("bar == 2")]))
	transition(b, a, "to_a")
	await finish_setup()
	
	# root state is active
	assert_active(a)
	assert_inactive(b)
	
	set_expression_property("foo", 0)
	set_expression_property("bar", 0)
	
	# when i send the event, the transition should not be taken, because both guards are false
	send_event("to_b")
	assert_active(a)
	assert_inactive(b)
	
	set_expression_property("foo", 1)
	set_expression_property("bar", 0)
	
	# when i send the event, the transition should be taken, because the first guard is true
	send_event("to_b")
	assert_active(b)
	assert_inactive(a)
	
	# back to a
	send_event("to_a")
	assert_active(a)
	
	set_expression_property("foo", 0)
	set_expression_property("bar", 2)
	
	# when i send the event, the transition should be taken, because the second guard is true
	send_event("to_b")
	assert_active(b)
	assert_inactive(a)
	
	# back to a
	send_event("to_a")
	assert_active(a)

	set_expression_property("foo", 1)
	set_expression_property("bar", 2)
	
	# when i send the event, the transition should be taken, because both guards are true
	send_event("to_b")
	assert_active(b)
	assert_inactive(a)
	
