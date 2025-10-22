extends StateChartTestBase

# Tests that history states work as expected.
func test_history_state_simple():
	var root := compound_state("root")
	
	var a := compound_state("a", root)
	var a1 := atomic_state("a1", a)
	var a2 := atomic_state("a2", a)
	var h := history_state("h", a, a1)

	transition(a1, a2, "to_a2")
	
	var b := atomic_state("b", root)
	transition(a, b, "exit_a")	
	transition(b, h, "return_to_a")
	
	await finish_setup()
	
	# now a1 should be active, as it is the initial state
	assert_active(a1)
	
	# when i send a transition to exit a
	send_event("exit_a")
	
	# then b should be active
	assert_active(b)
	assert_inactive(a1)
	
	# when i send a transition to return to a, then the history state should
	# remember that a1 was the last active state, so a1 should be active
	
	send_event("return_to_a")
	
	assert_active(a1)
	assert_inactive(b)
	
	# when i send a transition to a2, then a2 should be active
	send_event("to_a2")
	
	assert_active(a2)
	assert_inactive(a1)
	
	# when i send a transition to exit a
	send_event("exit_a")
	
	# then b should be active
	assert_active(b)
	
	# when i send a transition to return to a, then a2 should be active
	send_event("return_to_a")
	
	assert_active(a2)
	assert_inactive(a1)
	assert_inactive(b)
	
	
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
	
	

# Tests that deep history states restore nested substates correctly.
func test_history_state_deep_restores_nested_states() -> void:
	var root: CompoundState = compound_state("root")
	
	var a: CompoundState = compound_state("a", root)
	var a1: CompoundState = compound_state("a1", a)
	var a1a: AtomicState = atomic_state("a1a", a1)
	var a1b: AtomicState = atomic_state("a1b", a1)
	var a2: AtomicState = atomic_state("a2", a)
	var h: HistoryState = history_state("h", a, a1, true)
	
	transition(a1a, a1b, "to_a1b")
	
	var b: AtomicState = atomic_state("b", root)
	transition(a, b, "exit_a")
	transition(b, h, "return_to_a")
	
	await finish_setup()
	
	# Initial: a1a should be active (a1 is initial within a, a1a is initial within a1)
	assert_active(a1a)
	assert_inactive(b)
	
	# Move within nested compound a1
	send_event("to_a1b")
	assert_active(a1b)
	assert_inactive(a1a)
	
	# Leave 'a' entirely
	send_event("exit_a")
	assert_active(b)
	assert_inactive(a1b)

	# Return via deep history; should restore a1 with its nested state a1b (not a1a)
	send_event("return_to_a")
	assert_active(a1b)
	assert_inactive(b)
	

# Tests that pending transitions are saved in history and resume on restore.
func test_history_state_restores_pending_transition() -> void:
	var root: CompoundState = compound_state("root")
	
	var a: CompoundState = compound_state("a", root)
	var a1: AtomicState = atomic_state("a1", a)
	var a2: AtomicState = atomic_state("a2", a)
	var h: HistoryState = history_state("h", a, a1)
	
	# automatic delayed transition from a1 to a2 after 1 second
	transition(a1, a2, "", "1.0")
	
	var b: AtomicState = atomic_state("b", root)
	transition(a, b, "exit_a")
	transition(b, h, "return_to_a")
	
	await finish_setup()
	
	# Initially a1 should be active and its delayed transition pending
	assert_active(a1)
	
	# Wait 0.3s so about 0.7s remain for the pending transition
	await wait_seconds(0.3, "letting pending transition count down a bit")
	
	# Exit compound 'a' while the transition is still pending; history should store remaining time
	send_event("exit_a")
	assert_active(b)
	assert_inactive(a1)
	
	# Re-enter 'a' via history; the pending transition should resume, not restart from 1.0s
	send_event("return_to_a")
	# Immediately after restore we should still be in a1
	assert_active(a1)
	
	# After 0.4s it should still not have fired yet (we had ~0.7s remaining)
	await wait_seconds(0.4, "waiting less than the remaining time after restore")
	assert_active(a1)
	
	# After another 0.35s (total ~0.75s after restore), the pending transition should have fired
	await wait_seconds(0.35, "waiting beyond remaining time after restore")
	assert_active(a2)
	assert_inactive(a1)
	assert_inactive(b)
	


# Tests that shallow history restores only the immediate child and not nested substates.
func test_history_state_shallow_restores_only_immediate_child() -> void:
	var root: CompoundState = compound_state("root")
	
	var a: CompoundState = compound_state("a", root)
	var a1: CompoundState = compound_state("a1", a)
	var a1a: AtomicState = atomic_state("a1a", a1)
	var a1b: AtomicState = atomic_state("a1b", a1)
	var a2: AtomicState = atomic_state("a2", a)
	# shallow history
	var h: HistoryState = history_state("h", a, a1, false)
	
	transition(a1a, a1b, "to_a1b")
	
	var b: AtomicState = atomic_state("b", root)
	transition(a, b, "exit_a")
	transition(b, h, "return_to_a")
	
	await finish_setup()
	
	# Initial nested
	assert_active(a1a)
	
	# Move inside a1
	send_event("to_a1b")
	assert_active(a1b)
	
	# Exit compound 'a'
	send_event("exit_a")
	assert_active(b)
	
	# Re-enter via shallow history: expect a1 active BUT a1’s own initial (a1a), not a1b
	send_event("return_to_a")
	assert_active(a1a)
	assert_inactive(b)


# Coexistence: a shallow and a deep history node read from the same saved snapshot correctly.
func test_history_state_shallow_and_deep_coexist() -> void:
	var root: CompoundState = compound_state("root")
	var a: CompoundState = compound_state("a", root)
	var a1: CompoundState = compound_state("a1", a)
	var a1a: AtomicState = atomic_state("a1a", a1)
	var a1b: AtomicState = atomic_state("a1b", a1)
	var a2: AtomicState = atomic_state("a2", a)
	var h_shallow: HistoryState = history_state("h_shallow", a, a1, false)
	var h_deep: HistoryState = history_state("h_deep", a, a1, true)
	var b: AtomicState = atomic_state("b", root)
	
	transition(a1a, a1b, "to_a1b")
	transition(a, b, "exit_a")
	transition(b, h_shallow, "return_shallow")
	transition(b, h_deep, "return_deep")
	
	await finish_setup()
	
	# Default nested
	assert_active(a1a)
	
	# Change nested to a1b and exit
	send_event("to_a1b")
	assert_active(a1b)
	send_event("exit_a")
	assert_active(b)
	
	# Shallow restore: expect a1 active with its initial (a1a)
	send_event("return_shallow")
	assert_active(a1a)
	
	# Change nested again and exit
	send_event("to_a1b")
	assert_active(a1b)
	send_event("exit_a")
	assert_active(b)
	
	# Deep restore: expect a1b (full nested configuration)
	send_event("return_deep")
	assert_active(a1b)


# Using a history state before any history exists should activate its default state.
func test_history_state_uses_default_when_no_history_exists() -> void:
	var root: CompoundState = compound_state("root")
	# b is declared first so it becomes the initial state of the root
	var b: AtomicState = atomic_state("b", root)
	
	var a: CompoundState = compound_state("a", root)
	var a1: AtomicState = atomic_state("a1", a)
	var a2: AtomicState = atomic_state("a2", a)
	var h: HistoryState = history_state("h", a, a2)
	
	# go directly from b to h without ever having been in 'a'
	transition(b, h, "go_h")
	
	await finish_setup()
	assert_active(b)
	
	send_event("go_h")
	# should land in a2 via default since no history is saved yet
	assert_active(a2)
	assert_inactive(b)


# Transition to the compound itself should re-enter via its initial history state and restore last configuration.
func test_history_state_as_initial_on_self_transition_restores() -> void:
	var root: CompoundState = compound_state("root")
	var a: CompoundState = compound_state("a", root)
	var a1: AtomicState = atomic_state("a1", a)
	var a2: AtomicState = atomic_state("a2", a)
	var h: HistoryState = history_state("h", a, a1)
	
	# Make 'h' the initial state of 'a'
	a.initial_state = a.get_path_to(h)
	
	# transitions inside a
	transition(a1, a2, "to_a2")
	transition(a2, a1, "to_a1")
	# allow a child to trigger a transition targeting 'a' (self)
	transition(a1, a, "reenter_a")
	
	# sibling path to leave and re-enter a, so history is populated
	var b: AtomicState = atomic_state("b", root)
	transition(a, b, "exit_a")
	transition(b, a, "back_to_a")
	
	await finish_setup()
	# First activation of 'a' uses history initial: no history yet => default a1
	assert_active(a1)
	
	# Change to a2 and then exit a to store history
	send_event("to_a2")
	assert_active(a2)
	send_event("exit_a")
	assert_active(b)
	
	# Re-enter a; initial is history -> should restore a2
	send_event("back_to_a")
	assert_active(a2)
	
	# Move to a1
	send_event("to_a1")
	assert_active(a1)
	
	# Now trigger transition from a1 back to a (self) to exercise target==self path
	send_event("reenter_a")
	# Should still be in the last active substate (a1) after re-entering via history
	assert_active(a1)
