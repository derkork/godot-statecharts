using Godot;
using GodotStateCharts;


/// <summary>
/// This is an example of how to use the state chart from C#.
/// </summary>
// ReSharper disable once CheckNamespace
public partial class CSharpExample : Node2D
{
	
	private StateChart _stateChart;
	private Label _feelLabel;
	private int _health = 20;
	private StateChartState _poisonedStateChartState;
	
	public override void _Ready()
	{
		// Get the state chart node and wrap it in a StateChart object, so we can easily
		// interact with it from C#.
		_stateChart = StateChart.Of(GetNode("%StateChart"));
		
		// Get the poisoned state node and wrap it in a State object, so we can easily
		// interact with it from C#.
		_poisonedStateChartState = StateChartState.Of(GetNode("%Poisoned"));
		
		// The the UI label.
		_feelLabel = GetNode<Label>("%FeelLabel");
		RefreshUi();
	}

	/// <summary>
	/// Called when the drink poison button is pressed.
	/// </summary>
	private void OnDrinkPoisonButtonPressed()
	{
		// This uses the regular API to interact with the state chart.
		var currentPoisonCount = _stateChart.GetExpressionProperty("poison_count", 0);
		currentPoisonCount += 3; // we add three rounds worth of poison
		
		_stateChart.SetExpressionProperty("poison_count", currentPoisonCount);
		_stateChart.SendEvent("poisoned");
		
		// Ends the round
		EndRound();
	}
	
	/// <summary>
	/// Called when the drink cure button is pressed.
	/// </summary>
	private void OnDrinkCureButtonPressed()
	{
		// Here we use some custom-made extension methods from StateChartExt.cs to have a nicer API
		// that is specific to our game. This avoids having to use strings for property names and
		// event names and it also helps with type safety and when you need to find all places where
		// a certain property is set or an event is sent.
		_stateChart.SetPoisonCount(0);
		_stateChart.SendCuredEvent();
		
		// Ends the round
		EndRound();
	}

	/// <summary>
	/// Called when the next round button is pressed.
	/// </summary>
	private void OnWaitButtonPressed()
	{
		// Ends the round
		EndRound();	
	}


	private void EndRound()
	{
		// then send a "next_round" event
		_stateChart.SendEvent("next_round");
		// and finally call Step to calculate this round's effects, based on the current state
		_stateChart.Step();

		// Then at the beginning of the next round, we reduce any poison count by 1
		_stateChart.SetPoisonCount( Mathf.Max(0, _stateChart.GetPoisonCount() - 1));
		
		// And update the UI
		RefreshUi();
	}

	private void OnPoisonedStateStepped()
	{
		// when we step while poisoned, remove the amount of poison from our health (but not below 0)
		_health = Mathf.Max(0, _health - _stateChart.GetPoisonCount());
	}
	
	private void OnNormalStateStepped()
	{
		// when we step while not poisoned, heal 1 health, up to a maximum of 20
		_health = Mathf.Min(20, _health + 1);
	}
	
	
	private void RefreshUi()
	{
		_feelLabel.Text = $"Health: {_health} Poison: {_stateChart.GetPoisonCount()}";
	}

	private void OnDebugButtonPressed()
	{
		// States have an "Active" property that can be used to check if they are currently active.
		// Note that you should usually not use this in your game code, as it sort of defeats the
		// purpose of using a state chart. But it can be useful for debugging.
		GD.Print("Are we poisoned? ", _poisonedStateChartState.Active ? "Yes" : "No");	
	}

}
