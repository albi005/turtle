using System.Collections.Concurrent;
using System.Net.WebSockets;
using Hivemind.Data;

namespace Hivemind;

public class TurtleService(IServiceProvider serviceProvider) : IHostedService
{
    public ConcurrentDictionary<string, World> Worlds { get; } = [];

    public event Action? OnChanged;

    public void SendChanged() => OnChanged?.Invoke();

    public async Task Register(string worldId, byte dimensionId, uint turtleId, WebSocket webSocket,
        TaskCompletionSource tcs)
    {
        bool added = false;
        World world = Worlds.GetOrAdd(worldId, _ =>
        {
            added = true;
            return new(worldId);
        });
        if (added)
        {
            // TODO: move all 'is to a controller or something already scoped
            await using var scope = serviceProvider.CreateAsyncScope();
            var worldRepository = scope.ServiceProvider.GetRequiredService<WorldRepository>();

            // hopefully another request for the same world doesn't come in before this finishes
            await worldRepository.Add(world);
        }

        Dimension dimension = world.GetDimension(dimensionId);

        world.Turtles.AddOrUpdate(turtleId, _ =>
        {
            Turtle turtle = new(turtleId, world, dimension);
            turtle.Dimension = dimension;
            turtle.Connection = new(turtle, webSocket, tcs, serviceProvider);
            return turtle;
        }, (_, turtle) =>
        {
            turtle.Dimension = dimension;
            turtle.Connection = new(turtle, webSocket, tcs, serviceProvider);
            return turtle;
        });
        OnChanged?.Invoke();
    }

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        await using var scope = serviceProvider.CreateAsyncScope();
        var blockRepository = scope.ServiceProvider.GetRequiredService<BlockRepository>();
        var blocks = await blockRepository.GetAll();
        foreach (DbBlock block in blocks)
        {
            World world = Worlds.GetOrAdd(block.World.Name, static name => new(name));
            Dimension dimension = world.GetDimension(block.Dimension);
            Coordinates coordinates = new(block.X, block.Y, block.Z);
            dimension.Blocks[coordinates] = new(new(block.Type), block.LastUpdate);
        }
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}