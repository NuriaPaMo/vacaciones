# Identity Provider Selection - Code Examples

> **Progressive Disclosure**: These examples are bundled resources, loaded only when needed.
> They demonstrate complete, production-ready implementations across multiple identity providers and authorization models.

---

## 1. Microsoft Entra ID Authentication - ASP.NET Core Minimal API

**Scenario**: Secure HTTP API with JWT bearer authentication using Microsoft Entra ID.

**File: Program.cs**

```csharp
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Identity.Web;

var builder = WebApplication.CreateBuilder(args);

// Add Microsoft Identity Web authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

builder.Services.AddAuthorization();

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/api/protected", () =>
    Results.Ok(new { message = "You are authenticated!" }))
    .RequireAuthorization();

app.MapGet("/api/weather", (HttpContext context) =>
{
    var user = context.User;
    var name = user.Identity?.Name ?? "Unknown";
    var objectId = user.FindFirst("oid")?.Value ?? "N/A";

    return Results.Ok(new
    {
        Message = $"Hello, {name}!",
        ObjectId = objectId,
        Weather = new[] { "Sunny", "Cloudy", "Rainy" }
    });
})
.RequireAuthorization();

app.Run();
```

**File: appsettings.json**

```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "Domain": "yourtenant.onmicrosoft.com",
    "TenantId": "common",
    "ClientId": "your-api-client-id",
    "Audience": "api://your-api-client-id"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

**NuGet Packages:**

- Microsoft.Identity.Web (3.0+)
- Microsoft.AspNetCore.Authentication.JwtBearer

---

## 2. Microsoft Entra ID Authentication - React SPA with MSAL

**Scenario**: Single-Page Application with authorization code flow + PKCE.

**File: authConfig.ts**

```typescript
import { Configuration, PopupRequest } from '@azure/msal-browser';

export const msalConfig: Configuration = {
  auth: {
    clientId: 'your-spa-client-id',
    authority: 'https://login.microsoftonline.com/common',
    redirectUri: 'http://localhost:3000',
    postLogoutRedirectUri: 'http://localhost:3000',
  },
  cache: {
    cacheLocation: 'sessionStorage',
    storeAuthStateInCookie: false,
  },
};

export const loginRequest: PopupRequest = {
  scopes: ['User.Read', 'api://your-api-client-id/access_as_user'],
};

export const apiRequest = {
  scopes: ['api://your-api-client-id/access_as_user'],
};
```

**File: App.tsx**

```typescript
import React, { useEffect, useState } from 'react';
import { MsalProvider, useMsal, useIsAuthenticated } from '@azure/msal-react';
import { PublicClientApplication, InteractionRequiredAuthError } from '@azure/msal-browser';
import { msalConfig, apiRequest } from './authConfig';

const msalInstance = new PublicClientApplication(msalConfig);

const ProtectedContent: React.FC = () => {
  const { instance, accounts } = useMsal();
  const isAuthenticated = useIsAuthenticated();
  const [weatherData, setWeatherData] = useState<any>(null);

  const handleLogin = () => {
    instance.loginPopup().catch(e => {
      console.error('Login failed:', e);
    });
  };

  const handleLogout = () => {
    instance.logoutPopup().catch(e => {
      console.error('Logout failed:', e);
    });
  };

  const callProtectedApi = async () => {
    const account = accounts[0];

    try {
      // Acquire token silently
      const response = await instance.acquireTokenSilent({
        ...apiRequest,
        account: account
      });

      // Call API with bearer token
      const apiResponse = await fetch('https://localhost:7295/api/weather', {
        headers: {
          'Authorization': `Bearer ${response.accessToken}`
        }
      });

      const data = await apiResponse.json();
      setWeatherData(data);
    } catch (error) {
      if (error instanceof InteractionRequiredAuthError) {
        // Fallback to interactive method
        instance.acquireTokenPopup(apiRequest)
          .then(response => {
            // Retry API call with new token
            return fetch('https://localhost:7295/api/weather', {
              headers: { 'Authorization': `Bearer ${response.accessToken}` }
            });
          })
          .then(res => res.json())
          .then(data => setWeatherData(data));
      }
    }
  };

  if (!isAuthenticated) {
    return (
      <div>
        <h1>Welcome to My App</h1>
        <button onClick={handleLogin}>Sign In</button>
      </div>
    );
  }

  return (
    <div>
      <h1>Welcome, {accounts[0]?.name}</h1>
      <button onClick={handleLogout}>Sign Out</button>
      <button onClick={callProtectedApi}>Call Protected API</button>

      {weatherData && (
        <div>
          <h2>API Response:</h2>
          <pre>{JSON.stringify(weatherData, null, 2)}</pre>
        </div>
      )}
    </div>
  );
};

const App: React.FC = () => {
  return (
    <MsalProvider instance={msalInstance}>
      <ProtectedContent />
    </MsalProvider>
  );
};

export default App;
```

**npm packages:**

- @azure/msal-browser (^3.0.0)
- @azure/msal-react (^2.0.0)

---

## 3. Azure AD B2C Authentication - Customer-Facing Application

**Scenario**: External customer authentication with social providers and custom user flows.

**File: Program.cs (B2C API)**

```csharp
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Identity.Web;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(options =>
    {
        builder.Configuration.Bind("AzureAdB2C", options);
        options.TokenValidationParameters.NameClaimType = "name";
    },
    options => { builder.Configuration.Bind("AzureAdB2C", options); });

builder.Services.AddAuthorization();

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/api/profile", (HttpContext context) =>
{
    var user = context.User;
    return Results.Ok(new
    {
        Name = user.FindFirst("name")?.Value,
        Email = user.FindFirst("emails")?.Value,
        City = user.FindFirst("city")?.Value,
        PostalCode = user.FindFirst("postalCode")?.Value
    });
})
.RequireAuthorization();

app.Run();
```

**File: appsettings.json (B2C Configuration)**

```json
{
  "AzureAdB2C": {
    "Instance": "https://yourtenant.b2clogin.com/",
    "ClientId": "your-api-client-id",
    "Domain": "yourtenant.onmicrosoft.com",
    "SignUpSignInPolicyId": "B2C_1_susi",
    "Audience": "your-api-client-id"
  }
}
```

**File: authConfig.ts (B2C React SPA)**

```typescript
import { Configuration } from '@azure/msal-browser';

export const msalConfig: Configuration = {
  auth: {
    clientId: 'your-spa-client-id',
    authority: 'https://yourtenant.b2clogin.com/yourtenant.onmicrosoft.com/B2C_1_susi',
    knownAuthorities: ['yourtenant.b2clogin.com'],
    redirectUri: 'http://localhost:3000',
    postLogoutRedirectUri: 'http://localhost:3000',
  },
  cache: {
    cacheLocation: 'sessionStorage',
    storeAuthStateInCookie: false,
  },
};

export const apiConfig = {
  scopes: ['https://yourtenant.onmicrosoft.com/api/user_impersonation'],
  uri: 'https://localhost:7295/api/profile',
};

// Optional: Password reset flow
export const b2cPolicies = {
  names: {
    signUpSignIn: 'B2C_1_susi',
    forgotPassword: 'B2C_1_reset',
    editProfile: 'B2C_1_edit_profile',
  },
  authorities: {
    signUpSignIn: {
      authority: 'https://yourtenant.b2clogin.com/yourtenant.onmicrosoft.com/B2C_1_susi',
    },
    forgotPassword: {
      authority: 'https://yourtenant.b2clogin.com/yourtenant.onmicrosoft.com/B2C_1_reset',
    },
    editProfile: {
      authority: 'https://yourtenant.b2clogin.com/yourtenant.onmicrosoft.com/B2C_1_edit_profile',
    },
  },
};
```

---

## 4. JWT Token Validation Middleware - Custom Implementation

**Scenario**: Validate JWT tokens manually without Microsoft.Identity.Web (multi-tenant or custom issuer).

**File: JwtValidationMiddleware.cs**

```csharp
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

public class JwtValidationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IConfiguration _configuration;
    private readonly ConfigurationManager<OpenIdConnectConfiguration> _configurationManager;

    public JwtValidationMiddleware(RequestDelegate next, IConfiguration configuration)
    {
        _next = next;
        _configuration = configuration;

        var authority = configuration["AzureAd:Instance"] + configuration["AzureAd:TenantId"];
        var metadataAddress = $"{authority}/v2.0/.well-known/openid-configuration";

        _configurationManager = new ConfigurationManager<OpenIdConnectConfiguration>(
            metadataAddress,
            new OpenIdConnectConfigurationRetriever(),
            new HttpDocumentRetriever());
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var authHeader = context.Request.Headers["Authorization"].FirstOrDefault();

        if (authHeader?.StartsWith("Bearer ") == true)
        {
            var token = authHeader.Substring("Bearer ".Length).Trim();

            try
            {
                var claimsPrincipal = await ValidateTokenAsync(token);
                context.User = claimsPrincipal;
            }
            catch (SecurityTokenException ex)
            {
                context.Response.StatusCode = 401;
                await context.Response.WriteAsync($"Token validation failed: {ex.Message}");
                return;
            }
        }

        await _next(context);
    }

    private async Task<ClaimsPrincipal> ValidateTokenAsync(string token)
    {
        var openIdConfig = await _configurationManager.GetConfigurationAsync(CancellationToken.None);

        var validationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuers = new[]
            {
                $"https://login.microsoftonline.com/{_configuration["AzureAd:TenantId"]}/v2.0",
                $"https://sts.windows.net/{_configuration["AzureAd:TenantId"]}/"
            },
            ValidateAudience = true,
            ValidAudiences = new[] { _configuration["AzureAd:ClientId"], _configuration["AzureAd:Audience"] },
            ValidateLifetime = true,
            IssuerSigningKeys = openIdConfig.SigningKeys,
            ClockSkew = TimeSpan.FromMinutes(5)
        };

        var handler = new JwtSecurityTokenHandler();
        var claimsPrincipal = handler.ValidateToken(token, validationParameters, out var validatedToken);

        return claimsPrincipal;
    }
}

// Register in Program.cs
// app.UseMiddleware<JwtValidationMiddleware>();
```

---

## 5. RBAC with App Roles - .NET Implementation

**Scenario**: Implement role-based access control using Entra ID App Roles.

**File: Program.cs**

```csharp
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Identity.Web;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

builder.Services.AddAuthorization(options =>
{
    // Define policies based on app roles
    options.AddPolicy("AdminOnly", policy =>
        policy.RequireRole("Admin"));

    options.AddPolicy("ManagerOrAdmin", policy =>
        policy.RequireRole("Manager", "Admin"));

    options.AddPolicy("ReadAccess", policy =>
        policy.RequireRole("Reader", "Manager", "Admin"));
});

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

// Admin-only endpoint
app.MapGet("/api/admin/users", () =>
    Results.Ok(new { users = new[] { "Alice", "Bob", "Charlie" } }))
    .RequireAuthorization("AdminOnly");

// Manager or Admin endpoint
app.MapPost("/api/reports", (Report report) =>
    Results.Ok(new { message = "Report submitted" }))
    .RequireAuthorization("ManagerOrAdmin");

// Any authenticated user with Read role
app.MapGet("/api/data", () =>
    Results.Ok(new { data = "Sensitive information" }))
    .RequireAuthorization("ReadAccess");

// Custom authorization check
app.MapDelete("/api/resources/{id}",
    [Authorize(Roles = "Admin")]
    (int id, HttpContext context) =>
{
    var user = context.User;
    var roles = user.FindAll("roles").Select(c => c.Value);

    return Results.Ok(new
    {
        Message = $"Resource {id} deleted",
        UserRoles = roles
    });
});

app.Run();

record Report(string Title, string Content);
```

**Entra ID App Registration - Manifest (roles section):**

```json
{
  "appRoles": [
    {
      "allowedMemberTypes": ["User"],
      "description": "Administrators have full access",
      "displayName": "Admin",
      "id": "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890",
      "isEnabled": true,
      "value": "Admin"
    },
    {
      "allowedMemberTypes": ["User"],
      "description": "Managers can create reports",
      "displayName": "Manager",
      "id": "b2c3d4e5-f678-90a1-b2c3-d4e5f6789012",
      "isEnabled": true,
      "value": "Manager"
    },
    {
      "allowedMemberTypes": ["User"],
      "description": "Readers have read-only access",
      "displayName": "Reader",
      "id": "c3d4e5f6-7890-a1b2-c3d4-e5f678901234",
      "isEnabled": true,
      "value": "Reader"
    }
  ]
}
```

---

## 6. Claims-Based Authorization - Policy-Based Approach

**Scenario**: Fine-grained authorization using custom claims and policy requirements.

**File: AuthorizationPolicies.cs**

```csharp
using Microsoft.AspNetCore.Authorization;

public static class AuthorizationPolicies
{
    public static void AddCustomPolicies(this IServiceCollection services)
    {
        services.AddAuthorization(options =>
        {
            // Require specific claim value
            options.AddPolicy("EmployeesOnly", policy =>
                policy.RequireClaim("employee_id"));

            // Require department claim with specific values
            options.AddPolicy("EngineeringOrHR", policy =>
                policy.RequireClaim("department", "Engineering", "HR"));

            // Custom requirement
            options.AddPolicy("MinimumAge21", policy =>
                policy.Requirements.Add(new MinimumAgeRequirement(21)));

            // Combine multiple requirements
            options.AddPolicy("SeniorEngineer", policy =>
            {
                policy.RequireClaim("department", "Engineering");
                policy.RequireClaim("level", "Senior", "Principal", "Staff");
            });
        });

        services.AddSingleton<IAuthorizationHandler, MinimumAgeAuthorizationHandler>();
    }
}
```

**File: MinimumAgeRequirement.cs**

```csharp
using Microsoft.AspNetCore.Authorization;

public class MinimumAgeRequirement : IAuthorizationRequirement
{
    public int MinimumAge { get; }

    public MinimumAgeRequirement(int minimumAge)
    {
        MinimumAge = minimumAge;
    }
}

public class MinimumAgeAuthorizationHandler : AuthorizationHandler<MinimumAgeRequirement>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        MinimumAgeRequirement requirement)
    {
        var dateOfBirthClaim = context.User.FindFirst(c => c.Type == "date_of_birth");

        if (dateOfBirthClaim == null)
        {
            return Task.CompletedTask;
        }

        if (DateTime.TryParse(dateOfBirthClaim.Value, out var dateOfBirth))
        {
            var age = DateTime.Today.Year - dateOfBirth.Year;
            if (dateOfBirth.Date > DateTime.Today.AddYears(-age))
            {
                age--;
            }

            if (age >= requirement.MinimumAge)
            {
                context.Succeed(requirement);
            }
        }

        return Task.CompletedTask;
    }
}
```

**File: Program.cs (Usage)**

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

builder.Services.AddCustomPolicies();

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/api/employee/profile", (HttpContext context) =>
{
    var employeeId = context.User.FindFirst("employee_id")?.Value;
    return Results.Ok(new { employeeId });
})
.RequireAuthorization("EmployeesOnly");

app.MapPost("/api/restricted", () =>
    Results.Ok(new { message = "Age verified" }))
    .RequireAuthorization("MinimumAge21");

app.Run();
```

---

## 7. Service-to-Service Authentication - Client Credentials Flow

**Scenario**: Daemon application or background service authenticating to another API without user context.

**File: BackgroundService.cs**

```csharp
using Microsoft.Identity.Client;
using System.Net.Http.Headers;

public class ApiClientService : BackgroundService
{
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<ApiClientService> _logger;

    public ApiClientService(
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory,
        ILogger<ApiClientService> logger)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var accessToken = await GetAccessTokenAsync();
                await CallProtectedApiAsync(accessToken);

                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in background service");
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
        }
    }

    private async Task<string> GetAccessTokenAsync()
    {
        var clientId = _configuration["AzureAd:ClientId"];
        var clientSecret = _configuration["AzureAd:ClientSecret"];
        var tenantId = _configuration["AzureAd:TenantId"];
        var scope = _configuration["DownstreamApi:Scopes"];

        var app = ConfidentialClientApplicationBuilder.Create(clientId)
            .WithClientSecret(clientSecret)
            .WithAuthority(new Uri($"https://login.microsoftonline.com/{tenantId}"))
            .Build();

        var result = await app.AcquireTokenForClient(new[] { scope })
            .ExecuteAsync();

        return result.AccessToken;
    }

    private async Task CallProtectedApiAsync(string accessToken)
    {
        var httpClient = _httpClientFactory.CreateClient();
        httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", accessToken);

        var apiUrl = _configuration["DownstreamApi:BaseUrl"] + "/api/data";
        var response = await httpClient.GetAsync(apiUrl);

        if (response.IsSuccessStatusCode)
        {
            var content = await response.Content.ReadAsStringAsync();
            _logger.LogInformation("API call successful: {Content}", content);
        }
        else
        {
            _logger.LogWarning("API call failed: {StatusCode}", response.StatusCode);
        }
    }
}
```

**File: appsettings.json**

```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "your-tenant-id",
    "ClientId": "your-daemon-app-client-id",
    "ClientSecret": "your-client-secret"
  },
  "DownstreamApi": {
    "BaseUrl": "https://api.example.com",
    "Scopes": "api://downstream-api-client-id/.default"
  }
}
```

**NuGet Packages:**

- Microsoft.Identity.Client (4.60+)

---

## 8. Auth0 Integration - Node.js Express API

**Scenario**: Third-party identity provider integration with Node.js backend.

**File: server.js**

```javascript
const express = require('express');
const { auth } = require('express-oauth2-jwt-bearer');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

// Auth0 JWT validation middleware
const checkJwt = auth({
  audience: 'https://your-api-identifier',
  issuerBaseURL: 'https://your-tenant.auth0.com/',
  tokenSigningAlg: 'RS256',
});

// Public endpoint
app.get('/api/public', (req, res) => {
  res.json({ message: 'Public endpoint - no authentication required' });
});

// Protected endpoint
app.get('/api/protected', checkJwt, (req, res) => {
  res.json({
    message: 'Protected endpoint - authentication required',
    user: req.auth,
  });
});

// Endpoint with permissions check
const checkPermissions = (requiredPermissions) => {
  return (req, res, next) => {
    const permissions = req.auth?.permissions || [];

    const hasPermission = requiredPermissions.every((permission) =>
      permissions.includes(permission)
    );

    if (!hasPermission) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    next();
  };
};

app.post('/api/admin/users', checkJwt, checkPermissions(['create:users']), (req, res) => {
  res.json({ message: 'User created', data: req.body });
});

app.get(
  '/api/admin/reports',
  checkJwt,
  checkPermissions(['read:reports', 'read:admin']),
  (req, res) => {
    res.json({
      reports: [
        { id: 1, title: 'Q4 Revenue' },
        { id: 2, title: 'User Growth' },
      ],
    });
  }
);

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`API server listening on port ${PORT}`);
});
```

**File: auth0-config.js (React SPA)**

```javascript
import { Auth0Provider } from '@auth0/auth0-react';
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));

root.render(
  <React.StrictMode>
    <Auth0Provider
      domain="your-tenant.auth0.com"
      clientId="your-spa-client-id"
      authorizationParams={{
        redirect_uri: window.location.origin,
        audience: 'https://your-api-identifier',
        scope: 'openid profile email read:messages create:messages',
      }}
    >
      <App />
    </Auth0Provider>
  </React.StrictMode>
);
```

**File: ProtectedComponent.jsx**

```javascript
import React, { useState } from 'react';
import { useAuth0 } from '@auth0/auth0-react';

const ProtectedComponent = () => {
  const { isAuthenticated, isLoading, user, loginWithRedirect, logout, getAccessTokenSilently } =
    useAuth0();

  const [apiResponse, setApiResponse] = useState(null);

  const callProtectedApi = async () => {
    try {
      const accessToken = await getAccessTokenSilently({
        authorizationParams: {
          audience: 'https://your-api-identifier',
          scope: 'read:messages',
        },
      });

      const response = await fetch('http://localhost:3001/api/protected', {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });

      const data = await response.json();
      setApiResponse(data);
    } catch (error) {
      console.error('API call failed:', error);
    }
  };

  if (isLoading) {
    return <div>Loading...</div>;
  }

  if (!isAuthenticated) {
    return (
      <div>
        <h1>Welcome to My App</h1>
        <button onClick={() => loginWithRedirect()}>Log In</button>
      </div>
    );
  }

  return (
    <div>
      <h1>Welcome, {user?.name}</h1>
      <img src={user?.picture} alt={user?.name} />
      <button onClick={() => logout({ returnTo: window.location.origin })}>Log Out</button>
      <button onClick={callProtectedApi}>Call Protected API</button>

      {apiResponse && (
        <div>
          <h2>API Response:</h2>
          <pre>{JSON.stringify(apiResponse, null, 2)}</pre>
        </div>
      )}
    </div>
  );
};

export default ProtectedComponent;
```

**npm packages:**

- express-oauth2-jwt-bearer (^1.6.0)
- @auth0/auth0-react (^2.2.0)
- express (^4.18.0)

---

## Summary

These examples demonstrate:

1. **Microsoft Entra ID** - Enterprise identity with organizational accounts
2. **Azure AD B2C** - Customer-facing identity with social providers
3. **JWT Validation** - Custom token validation logic
4. **RBAC** - Role-based access control with app roles
5. **Claims-Based Authorization** - Fine-grained policy-based authorization
6. **Service-to-Service** - Daemon apps using client credentials flow
7. **Auth0** - Third-party identity provider integration

All examples are production-ready with proper error handling, token refresh, and security best practices.
