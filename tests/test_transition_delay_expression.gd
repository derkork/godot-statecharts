extends StateChartTestBase

func test_transition_delay_expression():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	transition(a, b, "to_b", "foo + bar")
	await finish_setup()

	set_expression_property("foo", 1)
	set_expression_property("bar", 0.5)

	# when i trigger the transition
	send_event("to_b")

	# then the transition should not be taken immediately
	assert_active(a)

	await wait_seconds(1)

	# after 1 second the transition should still not be taken (1.5 > 1)
	assert_active(a)

	await wait_seconds(1)

	# after 2 seconds the transition should be taken (1.5 > 1)
	assert_active(b)
	assert_inactive(a)
	
