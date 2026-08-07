// Aspire AppHost — local development service orchestration (constitution VIII-C)
// Dashboard available at http://localhost:15888 after dotnet run

var builder = DistributedApplication.CreateBuilder(args);

// ─── Infrastructure Services ──────────────────────────────────────────────────

var sqlServer = builder.AddSqlServer("sqlserver")
    .WithDataVolume("vacmgt-sqlserver-data");

var sqlDb = sqlServer.AddDatabase("vacmgt-db");

var redis = builder.AddRedis("redis")
    .WithRedisCommander();   // Redis Commander UI at :8001

var serviceBus = builder.AddAzureServiceBus("servicebus")
    .RunAsEmulator();        // Aspire Service Bus emulator for local dev

// ─── Backend API ──────────────────────────────────────────────────────────────

var api = builder.AddProject<Projects.VacationManagement_Api>("api")
    .WithReference(sqlDb)
    .WithReference(redis)
    .WithReference(serviceBus)
    .WithEnvironment("ASPNETCORE_ENVIRONMENT", "Development")
    .WithEnvironment("ASPNETCORE_URLS", "http://+:5000")
    .WithHttpEndpoint(name: "http", port: 5000);

// ─── Dashboard config ─────────────────────────────────────────────────────────
// Access Aspire Dashboard at https://localhost:15888
// All service logs, traces, and metrics aggregated there during local dev

builder.Build().Run();
