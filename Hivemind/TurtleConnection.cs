using System.Net.WebSockets;
using System.Text;

namespace Hivemind;

public class TurtleConnection
{
    private readonly WebSocket _webSocket;
    private readonly Turtle _turtle;

    public TurtleConnection(Turtle turtle, WebSocket webSocket, TaskCompletionSource tcs)
    {
        _turtle = turtle;
        _webSocket = webSocket;
        Task.Run(Run);
    }

    public async Task SendAsync(string message)
    {
        await _webSocket.SendAsync(Encoding.UTF8.GetBytes(message), WebSocketMessageType.Text, true, CancellationToken.None);
    }

    private async Task Run()
    {
        var buffer = new byte[1024 * 4];
        var receiveResult = await _webSocket.ReceiveAsync(
            new ArraySegment<byte>(buffer), CancellationToken.None);

        while (!receiveResult.CloseStatus.HasValue)
        {
            await _webSocket.SendAsync(
                new ArraySegment<byte>(buffer, 0, receiveResult.Count),
                receiveResult.MessageType,
                receiveResult.EndOfMessage,
                CancellationToken.None);

            receiveResult = await _webSocket.ReceiveAsync(
                new ArraySegment<byte>(buffer), CancellationToken.None);
        }

        _turtle.Connection = null;

        await _webSocket.CloseAsync(
            receiveResult.CloseStatus.Value,
            receiveResult.CloseStatusDescription,
            CancellationToken.None);
    }
}