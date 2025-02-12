extends StateChartTestBase

# https://github.com/derkork/godot-statecharts/issues/166
func test_deep_parallel_transition():
	# - Animation (Compound)
	#   - GeneralAnimation (Parallel)
	#       - Equipment (Compound)
	#          - Normal (Atomic)
	#          - Tool (Atomic)
	#          - Item (Atomic)
	#       - Action (Coumpound)
	#          - Idle (Atomic)
	#          - Motion (Atomic)
	#   - SpecialAnimation (Atomic)
	var root := compound_state("root")
	var animation := compound_state("animation", root)
	var general_animation := parallel_state("general_animation", animation)
	var equipment := compound_state("equipment", general_animation)
	var normal := atomic_state("normal", equipment)
	var tool := atomic_state("tool", equipment)
	var item := atomic_state("item", equipment)
	var action := compound_state("action", general_animation)
	var idle := atomic_state("idle", action)
	var motion := atomic_state("motion", action)
	var special_animation := atomic_state("special_animation", animation)
	
	# From SpecialAnimation, I have a transition that should lead to GeneralAnimation/Equipment/Tool
	transition(special_animation, tool, "some_event")
	
	# and just something to initialize this into the right state
	transition(general_animation, special_animation, "init_event")
	
	await finish_setup()
	
	# initialize state, so we start out in "SpecialAnimation"
	send_event("init_event")
	
	assert_active(special_animation)
	assert_inactive(general_animation)
	assert_inactive(equipment)
	assert_inactive(normal)
	assert_inactive(tool)
	assert_inactive(item)
	assert_inactive(action)
	assert_inactive(idle)
	assert_inactive(motion)
	
	send_event("some_event")

	# The Equipment branch should go to Tool, like I specified in the transition
	assert_active(equipment)
	assert_active(tool)
	# The Action branch should go to Idle, which is its default
	assert_active(action)
	assert_active(idle)
	assert_inactive(special_animation)
	
