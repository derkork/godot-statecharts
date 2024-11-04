extends StateChartTestBase

# Checks that multiple delayed transitions work.
# https://github.com/derkork/godot-statecharts/issues/148
func test_multiple_delayed_transitions_work():
	var root := compound_state("root")
	
	var think := atomic_state("think", root)
	var explore := atomic_state("explore", root)
	var inspect := atomic_state("inspect", root)
	
	transition(think, explore, "pick_destination")
	transition( explore, inspect, "target_reached", "1.0")
	transition( explore, think, "", "2.0")
	
	await finish_setup()
	
	assert_active(think)	

	# when I pick a destination
	send_event("pick_destination")
	
	# then I should be exploring
	assert_active(explore)
	
	# when I now reach the target
	await wait_seconds(1.1, "wait for target reached")
	send_event("target_reached")
	
	# then after 1 second I should be inspecting
	await wait_seconds(1.1, "wait for inspect")
	assert_active(inspect)
	
	
	
