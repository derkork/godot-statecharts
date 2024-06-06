extends StateChartTestBase

# Tests that a history state used as an initial state will work.
func test_history_state_as_initial_state():
	var root := compound_state("root")
	
	var a := compound_state("a", root)
	atomic_state("a1", a)
	var a2 := atomic_state("a2", a)
	var h := history_state("h", a, a2)

	# overwrite the initial state of a to be h
	a.initial_state = a.get_path_to(h)

	await finish_setup()
	
	# now a2 should be active, because h was initial state and the default
	# state of h is a2
	assert_active(a2)
