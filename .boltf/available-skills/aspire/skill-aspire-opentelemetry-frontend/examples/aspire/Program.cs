/**
 * Aspire AppHost Configuration for Frontend Apps
 *
 * Configures JavaScript/TypeScript frontend apps (Angular, React, Vue, etc.)
 * to integrate with Aspire's observability infrastructure.
 *
 * Key features:
 * - Automatically injects OTLP endpoint URL as environment variable
 * - Manages frontend lifecycle (start/stop with npm scripts)
 * - Enables distributed tracing across frontend and backend
 * - Configures service discovery for backend API references
 */

using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

// Example: Register backend API
var authApi = builder.AddProject<Projects.AuthApi>("auth-api")
    .WithExternalHttpEndpoints();

// Register frontend application
var frontend = builder.AddJavaScriptApp("frontend", "../../../src/frontend")
    .WithNpm()                          // Use npm as package manager
    .WithRunScript("start")             // npm run start
    .WithExternalHttpEndpoints()        // Allow external access (typically https://localhost:5001)
    .WithReference(authApi)             // Injects AUTH_API_HTTPS environment variable
    .WaitFor(authApi);                  // Ensure backend starts first

// Additional configuration for other backends
var tenantApi = builder.AddProject<Projects.TenantApi>("tenant-api")
    .WithExternalHttpEndpoints()
    .WaitFor(authApi);

// Frontend can reference multiple backends
frontend.WithReference(tenantApi);      // Injects TENANT_API_HTTPS environment variable

builder.Build().Run();
