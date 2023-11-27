namespace GodotStateCharts
{
    using Godot;

    /// <summary>
    /// A transition between two states. This class only exists to make the 
    /// signal names available in C#. It is not intended to be instantiated
    /// or otherwise used.
    /// </summary>
    public class Transition {
        public class SignalName : Godot.Node.SignalName
        {
            /// <summary>
            /// Called when the transition is taken.
            /// </summary>
            public static readonly StringName Taken = "taken";
        }
    }
}
