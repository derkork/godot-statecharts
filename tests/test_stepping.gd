extends StateChartTestBase

func test_stepping():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	
	transition(a, b, "to_b")
	
	await finish_setup()
	
	# a should be active right now.. 
	assert_active(a)
	
	# watch the signals of a and b
	watch_signals(a)
	watch_signals(b)
	
	# when i call step
	step()
	
	# then a should emit the "state_stepped" signal as it is active
	assert_signal_emitted(a, "state_stepped")
	
	# while b should not emit the signal
	assert_signal_not_emitted(b, "state_stepped")

	clear_signal_watcher()
	watch_signals(a)
	watch_signals(b)

	# when i now transition to b
	send_event("to_b")

	# then b should be active
	assert_active(b)
	
	# and if i now call step again
	step()
	
	# then b should emit the "state_stepped" signal
	assert_signal_emitted(b, "state_stepped")
	
	# while a should not emit the signal
	assert_signal_not_emitted(a, "state_stepped")
	
	
	
