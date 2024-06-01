extends StateChartTestBase

# Test that when automatic transition works when a state is entered
func test_automatic_transition_on_state_enter():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	
	transition(a, b, "")
	
	await finish_setup()
	
	# because we have the automatic transition to b, we should be in b
	# right after the setup phase
	assert_active(b)
	
	
