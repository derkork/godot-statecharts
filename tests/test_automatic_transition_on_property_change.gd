extends StateChartTestBase


func test_automatic_transition_on_property_change():
	# Ensure that we have an initial value for the property, to avoid error messages.
	set_initial_expression_properties({"x": 0})
	
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	
	transition(a, b, "", "0", expression_guard("x == 1"))

	await finish_setup()
	
	# initial state is a and should not change yet
	assert_active(a)

	set_expression_property("x", 1)
	
	# now the transition should have happened
	assert_active(b)
