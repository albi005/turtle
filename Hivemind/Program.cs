using System.Net.WebSockets;
using Hivemind;
using Hivemind.Components;
using Hivemind.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using MudBlazor.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();
builder.Services.AddMudServices();
builder.Services.AddControllers();
builder.Services.AddTransient<TurtleMessageHandler>();
builder.Services.AddScoped<WorldRepository>();
builder.Services.AddScoped<BlockRepository>();
builder.Services.AddSingleton<TurtleService>();
builder.Services.AddHostedService(sp => sp.GetRequiredService<TurtleService>());
builder.Services.AddDbContextFactory<Db>();
builder.Services.AddScoped(p => p
    .GetRequiredService<IDbContextFactory<Db>>()
    .CreateDbContext());

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
    app.UseHttpsRedirection();
}

app.UseStaticFiles();
app.MapGet("/", () => Results.File("/home/albi/src/turtle/lua/install.lua", "text/plain"));
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider("/home/albi/src/turtle/lua"),
    DefaultContentType = "text/plain",
    ServeUnknownFileTypes = true,
});
app.UseAntiforgery();
app.UseWebSockets();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();
app.MapControllers();

await using (var startupScope = app.Services.CreateAsyncScope())
{
    await startupScope.ServiceProvider.GetRequiredService<Db>().Database.MigrateAsync();
}

app.Run();

public class WebSocketController(TurtleService turtleService) : ControllerBase
{
    [Route("/ws")]
    public async Task Get([FromQuery] uint turtleId, [FromQuery] string worldId, [FromQuery] byte dimensionId)
    {
        if (HttpContext.WebSockets.IsWebSocketRequest)
        {
            using WebSocket webSocket = await HttpContext.WebSockets.AcceptWebSocketAsync(new WebSocketAcceptContext()
                { KeepAliveInterval = TimeSpan.FromSeconds(30) });
            TaskCompletionSource tcs = new();
            await turtleService.Register(worldId, dimensionId, turtleId, webSocket, tcs);
            await tcs.Task;
        }
        else
        {
            HttpContext.Response.StatusCode = StatusCodes.Status418ImATeapot;
        }
    }
}