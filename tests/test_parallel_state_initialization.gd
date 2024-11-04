extends StateChartTestBase

# https://github.com/derkork/godot-statecharts/issues/143
# currently disabled because it doesn't work yet.
func __test_parallel_state_initialization():
	var root := parallel_state("root")
	var a := atomic_state("a", root)
	var b := compound_state("b", root)
	var b1 := atomic_state("b1", b)
	var b2 := atomic_state("b2", b)
	
	transition(b1, b2, "some_event")
	a.state_entered.connect(func():
		send_event("some_event")	
	)
	
	
	await finish_setup()
	
	# a should be active right now.. 
	assert_active(a)
	
	# and b2 should be active
	assert_active(b2)
	
	
