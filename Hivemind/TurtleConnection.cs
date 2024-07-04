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
        await _webSocket.SendAsync(Encoding.UTF8.GetBytes(message), WebSocketMessageType.Text, true,
            CancellationToken.None);
    }

    private async Task Run()
    {
        byte[] buffer = new byte[1024];
        WebSocketReceiveResult? receiveResult;
        do
        {
            MemoryStream messageStream = new();
            do
            {
                receiveResult = await _webSocket.ReceiveAsync(buffer, CancellationToken.None);
                messageStream.Write(buffer, 0, receiveResult.Count);
            } while (!receiveResult.EndOfMessage);

            if (!receiveResult.CloseStatus.HasValue)
                await _turtle.MessageHandler.Handle(messageStream);
        } while (!receiveResult.CloseStatus.HasValue);

        _turtle.Connection = null;

        await _webSocket.CloseAsync(
            receiveResult.CloseStatus.Value,
            receiveResult.CloseStatusDescription,
            CancellationToken.None);
    }
}