extends StateChartTestBase

# Test that when automatic transition works when a state changes.
func test_automatic_transition_on_state_change():
	var root := parallel_state("root")
	var a := compound_state("a", root)
	var a1 := atomic_state("a1", a)
	var a2 := atomic_state("a2", a)

	var b := compound_state("b", root)
	var b1 := atomic_state("b1", b)
	var b2 := atomic_state("b2", b)
	
	# a1 -> a2 on "some_event"
	transition(a1, a2, "some_event")
	# a2 -> a1 automatic after 0.5 seconds
	transition(a2, a1, "", "0.5")
	
	# b1 -> b2 automatic when a2 becomes active
	transition(b1, b2, "", "0", state_is_active_guard(a2))
	# b2 -> b1 automatic when a1 becomes active
	transition(b2, b1, "", "0", state_is_active_guard(a1))
	
	
	await finish_setup()
	
	assert_active(a1)
	assert_active(b1)
	
	send_event("some_event")
	
	# a2 should be active because we actively transitioned to it	
	assert_active(a2)
	# b2 should be active because a2 became active
	assert_active(b2)
	
	# wait for a2 to fall back to a1
	await wait_seconds(0.7)

	# a1 should be active because we auto-transitioned back after delay
	assert_active(a1)
	# b1 should be active because a1 became active
	assert_active(b1)
	
	
	
