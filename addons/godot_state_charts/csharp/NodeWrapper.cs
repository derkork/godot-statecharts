// ReSharper disable once CheckNamespace
namespace GodotStateCharts
{
    using Godot;
    
    /// <summary>
    /// Base class for all wrapper classes. Provides some common functionality. Not to be used directly.
    /// </summary>
    public abstract class NodeWrapper
    {
        /// <summary>
        /// The wrapped node.
        /// </summary>
        protected readonly Node Wrapped;

        protected NodeWrapper(Node wrapped)
        {
            Wrapped = wrapped;
        }
          
        /// <summary>
        /// Allows to connect to signals on the wrapped node.
        /// </summary>
        /// <param name="signal"></param>
        /// <param name="method"></param>
        /// <param name="flags"></param>
        public void Connect(StringName signal, Callable method, uint flags = 0u)
        {
            Wrapped.Connect(signal, method, flags);
        }

    }
}
