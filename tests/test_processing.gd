extends StateChartTestBase

func test_processing_atomic_state():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)

	watch_signals(a)
	watch_signals(b)
	
	
	transition(a, b, "to_b")
	await finish_setup()
	
	assert_true(a.is_processing())
	assert_true(a.is_physics_processing())
	
	
	# state a is active
	assert_active(a)
	
	await wait_frames(10, "Run for a little while.")
	
	assert_signal_emitted(a, "state_processing")
	assert_signal_emitted(a, "state_physics_processing")

	assert_signal_not_emitted(b, "state_processing")
	assert_signal_not_emitted(b, "state_physics_processing")
	
	
	clear_signal_watcher()
	watch_signals(a)
	watch_signals(b)
	
	send_event("to_b")
	
	assert_active(b)
	
	await wait_frames(10, "Run for a little while.")
		
	assert_true(b.is_processing())
	assert_true(b.is_physics_processing())
	
	assert_signal_emitted(b, "state_processing")
	assert_signal_emitted(b, "state_physics_processing")

	assert_signal_not_emitted(a, "state_processing")
	assert_signal_not_emitted(a, "state_physics_processing")
	

	

	assert_active(b)
	assert_inactive(a)
	
