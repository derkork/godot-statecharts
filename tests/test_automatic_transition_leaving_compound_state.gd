extends StateChartTestBase

# Test that when automatic transition works when a compound state is left
func test_automatic_transition_leaving_compound_state():
	var root := compound_state("root")
	var a := compound_state("a", root)
	
	var a1 := atomic_state("a1", a)
	var a2 := atomic_state("a2", a)
	
	var b := atomic_state("b", root)
	
	transition(a, b, "")
	
	await finish_setup()
	
	# because we have the automatic transition to b, we should be in b
	# right after the setup phase
	assert_active(b)
	
	assert_inactive(a)
	assert_inactive(a1)
	assert_inactive(a2)
	
	
