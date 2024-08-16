using System;
using Godot;

namespace GodotStateCharts;

public class TypeSafeSignal<R>
{
    private readonly Node _node;
    private readonly StringName _signalName;

    public TypeSafeSignal(Node node, StringName signalName)
    {
        _node = node;
        _signalName = signalName;
    }

    public void Connect(TypeSafeReceiver<R> receiver)
    {
        _node.Connect(_signalName, receiver.Callable);
    }

    public void Disconnect(TypeSafeReceiver<R> receiver)
    {
        _node.Disconnect(_signalName, receiver.Callable);
    }
}

public struct TypeSafeReceiver<TR>
{
    internal TypeSafeReceiver(Callable callable)
    {
        Callable = callable;
    }

    public Callable Callable { get; }
}

public static class TypeSafeExtensions
{
    public static void Connect(this TypeSafeSignal<Action> signal, Action action)
    {
        signal.Connect(new TypeSafeReceiver<Action>(Callable.From(action)));
    }

    public static void Disconnect(this TypeSafeSignal<Action> signal, Action action)
    {
        signal.Disconnect(new TypeSafeReceiver<Action>(Callable.From(action)));
    }

    public static void Connect<T>(this TypeSafeSignal<T> signal, Action<T> action)
    {
        signal.Connect(new TypeSafeReceiver<T>(Callable.From(action)));
    }

    public static void Disconnect<T>(this TypeSafeSignal<T> signal, Action<T> action)
    {
        signal.Disconnect(new TypeSafeReceiver<T>(Callable.From(action)));
    }

// two args

    public static void Connect<T1, T2>(this TypeSafeSignal<Action<T1, T2>> signal, Action<T1, T2> action)
    {
        signal.Connect(new TypeSafeReceiver<Action<T1, T2>>(Callable.From(action)));
    }

    public static void Disconnect<T1, T2>(this TypeSafeSignal<Action<T1, T2>> signal, Action<T1, T2> action)
    {
        signal.Disconnect(new TypeSafeReceiver<Action<T1, T2>>(Callable.From(action)));
    }

// three args

    public static void Connect<T1, T2, T3>(this TypeSafeSignal<Action<T1, T2, T3>> signal, Action<T1, T2, T3> action)
    {
        signal.Connect(new TypeSafeReceiver<Action<T1, T2, T3>>(Callable.From(action)));
    }

    public static void Disconnect<T1, T2, T3>(this TypeSafeSignal<Action<T1, T2, T3>> signal, Action<T1, T2, T3> action)
    {
        signal.Disconnect(new TypeSafeReceiver<Action<T1, T2, T3>>(Callable.From(action)));
    }
}
