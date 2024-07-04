using System.Collections.Concurrent;
using System.Net.WebSockets;
using Hivemind.Data;
using Microsoft.EntityFrameworkCore;

namespace Hivemind;

public class TurtleService(IDbContextFactory<Db> dbContextFactory, IServiceProvider serviceProvider) : IHostedService
{
    public ConcurrentDictionary<string, World> Worlds { get; } = [];

    public event Action? OnChanged;

    public void Register(string worldId, byte dimensionId, uint turtleId, WebSocket webSocket, TaskCompletionSource tcs)
    {
        World world = Worlds.GetOrAdd(worldId, _ => new(worldId));
        Dimension dimension = world.GetDimension(dimensionId);

        world.Turtles.AddOrUpdate(turtleId, _ =>
        {
            Turtle turtle = new(turtleId, world, dimension, serviceProvider.GetRequiredService<TurtleMessageHandler>());
            turtle.MessageHandler.Turtle = turtle;
            turtle.Dimension = dimension;
            turtle.Connection = new(turtle, webSocket, tcs);
            return turtle;
        }, (_, turtle) =>
        {
            turtle.Dimension = dimension;
            turtle.Connection = new(turtle, webSocket, tcs);
            return turtle;
        });
        OnChanged?.Invoke();
    }

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        await using Db db = await dbContextFactory.CreateDbContextAsync(cancellationToken);

        var blocks = await db.Blocks
            .AsNoTrackingWithIdentityResolution()
            .Include(block => block.World)
            .ToListAsync(cancellationToken);
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    public Task Update(string worldId, List<BlockUpdate> updates)
    {
        throw new NotImplementedException();
    }
}
