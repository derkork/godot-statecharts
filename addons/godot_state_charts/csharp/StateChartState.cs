﻿// ReSharper disable once CheckNamespace

namespace GodotStateCharts
{
    using Godot;
    using System;

    /// <summary>
    /// A wrapper around the state node that allows interacting with it from C#.
    /// </summary>
    public class StateChartState : NodeWrapper
    {
        public TypeSafeSignal<Action> StateEntered { get; }
        public TypeSafeSignal<Action> StateExited { get;  }
        public TypeSafeSignal<Action<StringName>> EventReceived { get;  }
        
        public TypeSafeSignal<Action<float>> StateProcessing { get;  }
        public TypeSafeSignal<Action<float>> StatePhysicsProcessing { get;  }
        
        public TypeSafeSignal<Action> StateStepped { get;  }
        
        public TypeSafeSignal<Action<InputEvent>> StateInput { get;  }
        
        public TypeSafeSignal<Action<InputEvent>> StateUnhandledInput { get;  }
        
        public TypeSafeSignal<Action<float,float>> TransitionPending { get;  }

        protected StateChartState(Node wrapped) : base(wrapped)
        {
            StateEntered = new TypeSafeSignal<Action>(Wrapped, SignalName.StateEntered);
            StateExited = new TypeSafeSignal<Action>(Wrapped, SignalName.StateExited);
            EventReceived = new TypeSafeSignal<Action<StringName>>(Wrapped, SignalName.EventReceived);
            StateProcessing = new TypeSafeSignal<Action<float>>(Wrapped, SignalName.StateProcessing);
            StatePhysicsProcessing = new TypeSafeSignal<Action<float>>(Wrapped, SignalName.StatePhysicsProcessing);
            StateStepped = new TypeSafeSignal<Action>(Wrapped, SignalName.StateStepped);
            StateInput = new TypeSafeSignal<Action<InputEvent>>(Wrapped, SignalName.StateInput);
            StateUnhandledInput = new TypeSafeSignal<Action<InputEvent>>(Wrapped, SignalName.StateUnhandledInput);
            TransitionPending = new TypeSafeSignal<Action<float,float>>(Wrapped, SignalName.TransitionPending);
        }

        /// <summary>
        /// Creates a wrapper object around the given node and verifies that the node
        /// is actually a state. The wrapper object can then be used to interact
        /// with the state chart from C#.
        /// </summary>
        /// <param name="state">the node that is the state</param>
        /// <returns>a State wrapper.</returns>
        /// <throws>ArgumentException if the node is not a state.</throws>
        public static StateChartState Of(Node state)
        {
            if (state.GetScript().As<Script>() is not GDScript gdScript ||
                !gdScript.ResourcePath.EndsWith("state.gd"))
            {
                throw new ArgumentException("Given node is not a state.");
            }

            return new StateChartState(state);
        }

        /// <summary>
        /// Returns true if this state is currently active.
        /// </summary>
        public bool Active => Wrapped.Get("active").As<bool>();

      
        public class SignalName : Godot.Node.SignalName
        {

            /// <summary>
            /// Called when the state is entered.
            /// </summary>
            public static readonly StringName StateEntered = "state_entered";

            /// <summary>
            ///  Called when the state is exited.
            /// </summary>
            public static readonly StringName StateExited = "state_exited";

            /// <summary>
            /// Called when the state receives an event. Only called if the state is active.
            /// </summary>
            public static readonly StringName EventReceived = "event_received";
    
            /// <summary>
            /// Called when the state is processing.
            /// </summary>
            public static readonly StringName StateProcessing = "state_processing";

            /// <summary>
            /// Called when the state is physics processing.
            /// </summary>
            public static readonly StringName StatePhysicsProcessing = "state_physics_processing";
            
            /// <summary>
            /// Called when the state chart <code>Step</code> function is called.
            /// </summary>
            public static readonly StringName StateStepped = "state_stepped";

            /// <summary>
            /// Called when the state is receiving input.
            /// </summary>
            public static readonly StringName StateInput = "state_input";
                
            
            /// <summary>
            /// Called when the state is receiving unhandled input.
            /// </summary>
            public static readonly StringName StateUnhandledInput = "state_unhandled_input";
            
            /// <summary>
            /// Called every frame while a delayed transition is pending for this state.
            /// Returns the initial delay and the remaining delay of the transition.
            /// </summary>
            public static readonly StringName TransitionPending = "transition_pending";
            
        }
    }
}
