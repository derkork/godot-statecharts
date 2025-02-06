extends StateChartTestBase


# https://github.com/derkork/godot-statecharts/issues/164
func test_initial_state_bypass_on_deep_transition():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := compound_state("b", root)
	var b1 := atomic_state("b1", b)
	var b2 := atomic_state("b2", b)

	var holder:Array[bool] = [false]
	
	transition(a, b2, "some_event")
	
	b1.state_entered.connect(func():
		holder[0] = true
	)
	
	await finish_setup()
	
	assert_active(a)
	assert_inactive(b)
	
	# WHEN
	send_event("some_event")
	
	# THEN 
	assert_active(b2)
	assert_inactive(b1)
	
	# and b1 should have never been activated even though it is the
	# initial state, because a deep transition bypasses initial state
	assert_false(holder[0])
	
	
func test_initial_state_bypass_on_deep_transition_parallel_states():
	var root := compound_state("root")
	var invalid_item := atomic_state("invalid_item", root)
	var valid_item := compound_state("valid_item", root)
	var active_tile := parallel_state("active_tile", valid_item)
	var operation := compound_state("operation", active_tile)
	var disabled := atomic_state("disabled", operation)
	var enabled := compound_state("enabled", operation)
	var mouse := atomic_state("mouse", enabled)
	var controller := atomic_state("controller", enabled)

	var holder:Array[bool] = [false]
	
	transition(invalid_item, mouse, "some_event")
	
	disabled.state_entered.connect(func():
		holder[0] = true
	)
	
	await finish_setup()
	
	assert_active(invalid_item)
	assert_inactive(mouse)
	
	# WHEN 
	send_event("some_event")
	
	# THEN 
	assert_active(mouse)
	assert_inactive(disabled)
	
	# and disabled should have never been activated even though it is the
	# initial state, because a deep transition bypasses initial state
	assert_false(holder[0])
