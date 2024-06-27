using System.Net.WebSockets;
using Hivemind;
using Hivemind.Components;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.FileProviders;
using MudBlazor.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();
builder.Services.AddMudServices();
builder.Services.AddControllers();
builder.Services.AddSingleton<TurtleService>();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
    app.UseHttpsRedirection();
}

app.UseStaticFiles();
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

// app.MapGet("/",
//     // async ctx => TypedResults.PhysicalFile("/home/albi/src/turtle/install.lua", "text/plain"));
//     async ctx => TypedResults.PhysicalFile("app.css", "text/plain"));


// app.Use(async (context, next) =>
// {
//     bool turtle = context.Request.Headers.UserAgent.FirstOrDefault()?.Contains("computercraft") ?? false;
//     // Do work that can write to the Response.
//     await next.Invoke();
//     // Do logging or other work that doesn't write to the Response.
// });

app.Run();

[ApiController]
public class MyController : Controller
{
    [HttpGet("/")]
    public PhysicalFileResult Get()
    {
        return PhysicalFile("/home/albi/src/turtle/lua/install.lua", "text/plain");
    }
}

public class WebSocketController(TurtleService turtleService) : ControllerBase
{
    [Route("/ws")]
    public async Task Get([FromQuery] string label)
    {
        if (HttpContext.WebSockets.IsWebSocketRequest)
        {
            using WebSocket webSocket = await HttpContext.WebSockets.AcceptWebSocketAsync();
            TaskCompletionSource tcs = new();
            Turtle turtle = new(label, webSocket, tcs);
            turtleService.Turtles.Add(turtle);
            await tcs.Task;
        }
        else
        {
            HttpContext.Response.StatusCode = StatusCodes.Status400BadRequest;
        }
    }
}