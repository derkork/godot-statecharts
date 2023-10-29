// ReSharper disable once CheckNamespace

namespace GodotStateCharts
{
    using Godot;
    using System;

    /// <summary>
    /// Wrapper around the GDScript state chart node. Allows interacting with the state chart.
    /// </summary>
    public class StateChart : NodeWrapper
    {
        private StateChart(Node wrapped) : base(wrapped)
        {
        }

        /// <summary>
        /// Creates a wrapper object around the given node and verifies that the node
        /// is actually a state chart. The wrapper object can then be used to interact
        /// with the state chart from C#.
        /// </summary>
        /// <param name="stateChart">the node that is the state chart</param>
        /// <returns>a StateChart wrapper.</returns>
        /// <throws>ArgumentException if the node is not a state chart.</throws>
        public static StateChart Of(Node stateChart)
        {
            if (stateChart.GetScript().As<Script>() is not GDScript gdScript
                || !gdScript.ResourcePath.EndsWith("state_chart.gd"))
            {
                throw new ArgumentException("Given node is not a state chart.");
            }

            return new StateChart(stateChart);
        }

        /// <summary>
        /// Sends an event to the state chart node.
        /// </summary>
        /// <param name="eventName">the name of the event to send</param>
        public void SendEvent(string eventName)
        {
            Wrapped.Call("send_event", eventName);
        }

        /// <summary>
        /// Sets an expression property on the state chart node for later use with expression guards.
        /// </summary>
        /// <param name="name">the name of the property to set. This is case sensitive.</param>
        /// <param name="value">the value to set the property to.</param>
        public void SetExpressionProperty(string name, Variant value)
        {
            Wrapped.Call("set_expression_property", name, value);
        }

        /// <summary>
        /// Steps the state chart node. This will invoke all <code>state_stepped</code> signals on the
        /// currently active states in the state charts. See the "Stepping Mode" section of the manual
        /// for more details.
        /// </summary>
        public void Step()
        {
            Wrapped.Call("step");
        }

        public class SignalName : Node.SignalName
        {
            /// <summary>
            /// Emitted when the state chart receives an event. This will be 
            /// emitted no matter which state is currently active and can be 
            /// useful to trigger additional logic elsewhere in the game 
            /// without having to create a custom event bus. It is also used
            /// by the state chart debugger. Note that this will emit the 
            /// events in the order in which they are processed, which may 
            /// be different from the order in which they were received. This is
            /// because the state chart will always finish processing one event
            /// fully before processing the next. If an event is received
            /// while another is still processing, it will be enqueued.
            /// </summary>
            public static readonly StringName EventReceived = "event_received";
        }
    }
}
