
using GodotStateCharts;

/// <summary>
/// This is an example on how to add extension methods to the state chart class to get
/// more type safety and a nicer API.
/// </summary>
// ReSharper disable once CheckNamespace
public static class StateChartExt
{
    public static void SetPoisonCount(this StateChart stateChart, int poisonCount)
    {
        stateChart.SetExpressionProperty("poison_count", poisonCount);
    }
    
    public static int GetPoisonCount(this StateChart stateChart)
    {
        return stateChart.GetExpressionProperty("poison_count", 0);
    }
    
    public static void SendCuredEvent(this StateChart stateChart)
    {
        stateChart.SendEvent("cured");
    }
}
