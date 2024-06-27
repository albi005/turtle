using System.Collections.ObjectModel;
using System.Net.WebSockets;

namespace Hivemind;

public class TurtleService
{
    public ObservableCollection<Turtle> Turtles { get; } = [];
}

public record Turtle(string Name, WebSocket WebSocket, TaskCompletionSource Tcs);