// ReSharper disable once CheckNamespace

namespace GodotStateCharts
{
    using Godot;
    using System;

    /// <summary>
    /// A wrapper around the state node that allows interacting with it from C#.
    /// </summary>
    public class StateChartState : NodeWrapper
    {
        protected StateChartState(Node wrapped) : base(wrapped) 
        {
            // Connect the signals to the events
            wrapped.Connect(SignalName.StateEntered, Callable.From(OnStateEntered));
            wrapped.Connect(SignalName.StateExited, Callable.From(OnStateExited));
            wrapped.Connect(SignalName.EventReceived, Callable.From<string>(OnEventReceived));
            wrapped.Connect(SignalName.StateProcessing, Callable.From<float>(OnStateProcessing));
            wrapped.Connect(SignalName.StatePhysicsProcessing, Callable.From<float>(OnStatePhysicsProcessing));
            wrapped.Connect(SignalName.StateStepped, Callable.From(OnStateStepped));
            wrapped.Connect(SignalName.StateInput, Callable.From<InputEvent>(OnStateInput));
            wrapped.Connect(SignalName.StateUnhandledInput, Callable.From<InputEvent>(OnStateUnhandledInput));
            wrapped.Connect(SignalName.TransitionPending, Callable.From<(float, float)>(OnTransitionPending));
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

        // Custom events for the signals
        public event Action StateEntered;
        public event Action StateExited;
        public event Action<string> EventReceived;
        public event Action<float> StateProcessing;
        public event Action<float> StatePhysicsProcessing;
        public event Action StateStepped;
        public event Action<InputEvent> StateInput;
        public event Action<InputEvent> StateUnhandledInput;
        public event Action<float, float> TransitionPending;

        // Methods to raise the events
        private void OnStateEntered() => StateEntered?.Invoke();
        private void OnStateExited() => StateExited?.Invoke();
        private void OnEventReceived(string eventName) => EventReceived?.Invoke(eventName);
        private void OnStateProcessing(float delta) => StateProcessing?.Invoke(delta);
        private void OnStatePhysicsProcessing(float delta) => StatePhysicsProcessing?.Invoke(delta);
        private void OnStateStepped() => StateStepped?.Invoke();
        private void OnStateInput(InputEvent inputEvent) => StateInput?.Invoke(inputEvent);
        private void OnStateUnhandledInput(InputEvent inputEvent) => StateUnhandledInput?.Invoke(inputEvent);
        private void OnTransitionPending((float initialDelay, float remainingDelay) delays) => TransitionPending?.Invoke(delays.initialDelay, delays.remainingDelay);

        public new class SignalName : Godot.Node.SignalName
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
