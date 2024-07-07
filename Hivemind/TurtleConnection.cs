using System.Net.WebSockets;
using System.Text;

namespace Hivemind;

public class TurtleConnection
{
    private readonly WebSocket _webSocket;
    private readonly Turtle _turtle;
    private readonly IServiceProvider _serviceProvider;

    public TurtleConnection(Turtle turtle, WebSocket webSocket, TaskCompletionSource tcs,
        IServiceProvider serviceProvider)
    {
        _turtle = turtle;
        _webSocket = webSocket;
        _serviceProvider = serviceProvider;
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

            if (receiveResult.CloseStatus.HasValue) break;
            await using var scope = _serviceProvider.CreateAsyncScope();
            var messageHandler = scope.ServiceProvider.GetRequiredService<TurtleMessageHandler>();
            messageHandler.Turtle = _turtle;
            await messageHandler.Handle(messageStream);
        } while (true);

        _turtle.Connection = null;

        await _webSocket.CloseAsync(
            receiveResult.CloseStatus.Value,
            receiveResult.CloseStatusDescription,
            CancellationToken.None);
    }
}