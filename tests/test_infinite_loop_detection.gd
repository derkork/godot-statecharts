extends StateChartTestBase

func test_infinite_loop_detection():
	var root := compound_state("root")
	
	var a := atomic_state("a" ,root)
	var b := atomic_state("b" ,root)
	
	transition(a, b, "")
	transition(b, a, "")
	
	await finish_setup()
	
	pass_test("No infinite loop. Nice.")
	
	
