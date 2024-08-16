using System;

namespace GodotStateCharts
{
    using Godot;

    /// <summary>
    /// A transition between two states. 
    /// </summary>
    public class Transition : NodeWrapper {
        
        /// <summary>
        /// Called when the transition is taken.
        /// </summary>
        public event Action Taken {
            add => Wrapped.Connect(SignalName.Taken, Callable.From(value));
            remove => Wrapped.Disconnect(SignalName.Taken, Callable.From(value));
        }
        
        private Transition(Node transition) : base(transition) {}
        
        public static Transition Of(Node transition) {
            if (transition.GetScript().As<Script>() is not GDScript gdScript
                || !gdScript.ResourcePath.EndsWith("transition.gd"))
            {
                throw new ArgumentException("Given node is not a transition.");
            }
            return new Transition(transition);
        }
        
        
        public class SignalName : Godot.Node.SignalName
        {
            /// <see cref="Transition.Taken"/>
            public static readonly StringName Taken = "taken";
        }
    }
}
