extends StateChartTestBase

func test_not_guard():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)

	transition(a, b, "to_b", "0", not_guard(expression_guard("foo == 1")))
	await finish_setup()

	assert_active(a)
	assert_inactive(b)
	set_expression_property("foo", 1)
	
	
	# if i send the event, the transition should not be taken, because the expression is true, and the not_guard is false
	send_event("to_b")
	
	assert_active(a)
	assert_inactive(b)
	
	set_expression_property("foo", 0)
	
	# if i send the event, the transition should be taken, because the expression is false, and the not_guard is true
	send_event("to_b")
	
	assert_inactive(a)
	assert_active(b)
	
