extends StateChartTestBase

func test_manual_transaction_trigger():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	
	
	# add a transition from a to b reacting on the "switch" event
	var t1 := transition(a, b, "switch", "3")
	# add a transition back from b to a reacting on the "switch" event	
	var t2 := transition(b, a, "switch", "3")

	await finish_setup()
	assert_active(a)
	assert_inactive(b)
	
	# when i manually trigger t1
	t1.take()
	
	# then we are immediately in b
	assert_active(b)
	assert_inactive(a)
	
	# when i manually trigger t2, but not immediately
	t2.take(false)
	
	# we still stay in b
	assert_active(b)
	assert_inactive(a)
	
	await get_tree().create_timer(3.5).timeout
	
	# and will then be in a after the time has passed
	assert_active(a)
	assert_inactive(b)


func test_cannot_trigger_transitions_in_inactive_states():
	var root := compound_state("root")
	var a := atomic_state("a", root)
	var b := atomic_state("b", root)
	var c := atomic_state("c", root)

	var t2 := transition(b, c, "switch")
	
	await finish_setup()
	assert_active(a)
	assert_inactive(b)
	assert_inactive(c)
	
	# when i manually trigger a transition in an inactive state
	t2.take()
	
	# then nothing will happen
	assert_active(a)
	assert_inactive(b)
	assert_inactive(c)
	
