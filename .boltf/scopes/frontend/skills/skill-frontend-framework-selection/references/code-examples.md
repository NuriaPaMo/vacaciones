# Frontend Framework Selection - Code Examples

Complete examples demonstrating React, Angular, Vue.js, Blazor, .NET MAUI, and React Native setup patterns for informed framework selection decisions.

---

## Example 1: React SPA with TypeScript and Azure Authentication

**Pattern**: React.js with TypeScript, MSAL.js for Microsoft Entra ID (Azure AD) authentication, modern hooks-based architecture.

**When to Use**: JavaScript/TypeScript ecosystem, large developer pool, component reusability, Azure authentication integration.

```typescript
// src/authConfig.ts
import { Configuration, PopupRequest } from '@azure/msal-browser';

export const msalConfig: Configuration = {
  auth: {
    clientId: process.env.REACT_APP_CLIENT_ID!,
    authority: `https://login.microsoftonline.com/${process.env.REACT_APP_TENANT_ID}`,
    redirectUri: window.location.origin,
  },
  cache: {
    cacheLocation: 'sessionStorage',
    storeAuthStateInCookie: false,
  },
};

export const loginRequest: PopupRequest = {
  scopes: ['User.Read', 'api://backend-api-id/access_as_user'],
};

// src/index.tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { PublicClientApplication } from '@azure/msal-browser';
import { MsalProvider } from '@azure/msal-react';
import App from './App';
import { msalConfig } from './authConfig';

const msalInstance = new PublicClientApplication(msalConfig);

const root = ReactDOM.createRoot(document.getElementById('root')!);
root.render(
  <React.StrictMode>
    <MsalProvider instance={msalInstance}>
      <App />
    </MsalProvider>
  </React.StrictMode>
);

// src/App.tsx
import React from 'react';
import { AuthenticatedTemplate, UnauthenticatedTemplate, useMsal } from '@azure/msal-react';
import { loginRequest } from './authConfig';
import Dashboard from './components/Dashboard';

function App() {
  const { instance } = useMsal();

  const handleLogin = () => {
    instance.loginPopup(loginRequest).catch((e) => {
      console.error('Login failed:', e);
    });
  };

  const handleLogout = () => {
    instance.logoutPopup();
  };

  return (
    <div className="App">
      <AuthenticatedTemplate>
        <nav>
          <button onClick={handleLogout}>Sign Out</button>
        </nav>
        <Dashboard />
      </AuthenticatedTemplate>
      <UnauthenticatedTemplate>
        <div>
          <h1>Welcome to React App</h1>
          <button onClick={handleLogin}>Sign In with Microsoft</button>
        </div>
      </UnauthenticatedTemplate>
    </div>
  );
}

export default App;

// src/components/Dashboard.tsx
import React, { useEffect, useState } from 'react';
import { useMsal } from '@azure/msal-react';
import { loginRequest } from '../authConfig';

interface UserData {
  displayName: string;
  mail: string;
}

function Dashboard() {
  const { instance, accounts } = useMsal();
  const [userData, setUserData] = useState<UserData | null>(null);

  useEffect(() => {
    const fetchUserData = async () => {
      if (accounts.length > 0) {
        const request = { ...loginRequest, account: accounts[0] };
        const response = await instance.acquireTokenSilent(request);

        // Call Microsoft Graph API
        const graphResponse = await fetch('https://graph.microsoft.com/v1.0/me', {
          headers: { Authorization: `Bearer ${response.accessToken}` },
        });
        const data = await graphResponse.json();
        setUserData(data);
      }
    };

    fetchUserData();
  }, [instance, accounts]);

  return (
    <div>
      <h2>Dashboard</h2>
      {userData && (
        <div>
          <p>Name: {userData.displayName}</p>
          <p>Email: {userData.mail}</p>
        </div>
      )}
    </div>
  );
}

export default Dashboard;
```

**Explanation**: React with MSAL.js provides straightforward Azure authentication via hooks (`useMsal`, `useIsAuthenticated`). Component-based architecture enables reusability. Large ecosystem (npm packages, TypeScript support, developer community).

---

## Example 2: Angular Application with Standalone Components

**Pattern**: Angular 17+ with standalone components, signals for reactive state, HTTP interceptors for API calls.

**When to Use**: Enterprise applications requiring strong typing, dependency injection, opinionated architecture, long-term maintainability.

```typescript
// src/main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { AppComponent } from './app/app.component';
import { routes } from './app/app.routes';
import { authInterceptor } from './app/core/interceptors/auth.interceptor';

bootstrapApplication(AppComponent, {
  providers: [provideRouter(routes), provideHttpClient(withInterceptors([authInterceptor]))],
}).catch((err) => console.error(err));

// src/app/app.component.ts
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { NavbarComponent } from './shared/navbar/navbar.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, NavbarComponent],
  template: `
    <app-navbar />
    <main class="container">
      <router-outlet />
    </main>
  `,
  styles: [
    `
      .container {
        padding: 2rem;
      }
    `,
  ],
})
export class AppComponent {
  title = 'Angular App';
}

// src/app/core/services/auth.service.ts
import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';

interface LoginResponse {
  token: string;
  user: { id: string; email: string };
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private tokenSignal = signal<string | null>(null);
  public token = this.tokenSignal.asReadonly();

  constructor(private http: HttpClient) {
    const storedToken = localStorage.getItem('auth_token');
    if (storedToken) this.tokenSignal.set(storedToken);
  }

  login(email: string, password: string): Observable<LoginResponse> {
    return this.http.post<LoginResponse>('/api/auth/login', { email, password }).pipe(
      tap((response) => {
        this.tokenSignal.set(response.token);
        localStorage.setItem('auth_token', response.token);
      })
    );
  }

  logout(): void {
    this.tokenSignal.set(null);
    localStorage.removeItem('auth_token');
  }

  isAuthenticated(): boolean {
    return this.token() !== null;
  }
}

// src/app/core/interceptors/auth.interceptor.ts
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthService } from '../services/auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const token = authService.token();

  if (token && !req.url.includes('/auth/login')) {
    const clonedRequest = req.clone({
      setHeaders: { Authorization: `Bearer ${token}` },
    });
    return next(clonedRequest);
  }

  return next(req);
};

// src/app/features/dashboard/dashboard.component.ts
import { Component, OnInit, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { CommonModule } from '@angular/common';

interface DashboardData {
  orders: number;
  revenue: number;
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  template: `
    <h2>Dashboard</h2>
    @if (loading()) {
      <p>Loading...</p>
    } @else if (data()) {
      <div class="stats">
        <div class="card">
          <h3>Orders</h3>
          <p>{{ data()!.orders }}</p>
        </div>
        <div class="card">
          <h3>Revenue</h3>
          <p>\${{ data()!.revenue }}</p>
        </div>
      </div>
    }
  `,
  styles: [
    `
      .stats {
        display: flex;
        gap: 1rem;
      }
      .card {
        padding: 1rem;
        border: 1px solid #ccc;
      }
    `,
  ],
})
export class DashboardComponent implements OnInit {
  data = signal<DashboardData | null>(null);
  loading = signal(true);

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.http.get<DashboardData>('/api/dashboard').subscribe({
      next: (response) => {
        this.data.set(response);
        this.loading.set(false);
      },
      error: (err) => {
        console.error('Failed to load dashboard:', err);
        this.loading.set(false);
      },
    });
  }
}
```

**Explanation**: Angular's opinionated architecture provides strong conventions (modules/standalone components, dependency injection, RxJS). Signals (Angular 16+) offer reactive state management. HTTP interceptors centralize authentication. Best for large enterprise apps with multiple teams.

---

## Example 3: Vue.js 3 Composition API with Pinia State Management

**Pattern**: Vue.js 3 with Composition API (setup script syntax), Pinia for global state, Vue Router for navigation.

**When to Use**: Progressive framework adoption, gentle learning curve, flexible architecture (can be simple or complex), integrates incrementally into existing apps.

```vue
<!-- src/main.ts -->
<script lang="ts">
import { createApp } from 'vue';
import { createPinia } from 'pinia';
import router from './router';
import App from './App.vue';

const app = createApp(App);
app.use(createPinia());
app.use(router);
app.mount('#app');
</script>

<!-- src/App.vue -->
<template>
  <div id="app">
    <nav v-if="authStore.isAuthenticated">
      <router-link to="/">Home</router-link>
      <router-link to="/dashboard">Dashboard</router-link>
      <button @click="authStore.logout">Logout</button>
    </nav>
    <router-view />
  </div>
</template>

<script setup lang="ts">
import { useAuthStore } from './stores/auth';

const authStore = useAuthStore();
</script>

<style scoped>
nav {
  display: flex;
  gap: 1rem;
  padding: 1rem;
  background: #f0f0f0;
}
</style>

<!-- src/stores/auth.ts -->
<script lang="ts">
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import axios from 'axios';

interface User {
  id: string;
  email: string;
  name: string;
}

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(localStorage.getItem('auth_token'));
  const user = ref<User | null>(null);

  const isAuthenticated = computed(() => token.value !== null);

  async function login(email: string, password: string) {
    try {
      const response = await axios.post('/api/auth/login', { email, password });
      token.value = response.data.token;
      user.value = response.data.user;
      localStorage.setItem('auth_token', token.value);
    } catch (error) {
      console.error('Login failed:', error);
      throw error;
    }
  }

  function logout() {
    token.value = null;
    user.value = null;
    localStorage.removeItem('auth_token');
  }

  async function fetchUser() {
    if (!token.value) return;
    try {
      const response = await axios.get('/api/auth/me', {
        headers: { Authorization: `Bearer ${token.value}` },
      });
      user.value = response.data;
    } catch (error) {
      console.error('Failed to fetch user:', error);
      logout();
    }
  }

  return { token, user, isAuthenticated, login, logout, fetchUser };
});
</script>

<!-- src/views/Dashboard.vue -->
<template>
  <div class="dashboard">
    <h2>Dashboard</h2>
    <p v-if="loading">Loading...</p>
    <div v-else-if="data" class="stats">
      <div class="card">
        <h3>Orders</h3>
        <p>{{ data.orders }}</p>
      </div>
      <div class="card">
        <h3>Revenue</h3>
        <p>${{ data.revenue }}</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import axios from 'axios';

interface DashboardData {
  orders: number;
  revenue: number;
}

const data = ref<DashboardData | null>(null);
const loading = ref(true);

onMounted(async () => {
  try {
    const response = await axios.get<DashboardData>('/api/dashboard');
    data.value = response.data;
  } catch (error) {
    console.error('Failed to load dashboard:', error);
  } finally {
    loading.value = false;
  }
});
</script>

<style scoped>
.dashboard {
  padding: 2rem;
}
.stats {
  display: flex;
  gap: 1rem;
}
.card {
  padding: 1rem;
  border: 1px solid #ccc;
}
</style>
```

**Explanation**: Vue 3's Composition API with `<script setup>` provides concise component logic. Pinia offers intuitive state management (simpler than Vuex). Reactive refs and computed properties make state updates straightforward. Progressive framework allows incremental adoption (can start with simple scripts, scale to SPA).

---

## Example 4: Blazor WebAssembly with Authentication

**Pattern**: Blazor WebAssembly running .NET in the browser via WebAssembly, Microsoft Entra ID authentication, C# for UI logic.

**When to Use**: .NET/C# team expertise, code sharing between frontend/backend, strong typing, fewer context switches for .NET developers.

```csharp
// Program.cs
using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using Microsoft.AspNetCore.Components.WebAssembly.Authentication;
using BlazorApp;

var builder = WebAssemblyHostBuilder.CreateDefault(args);
builder.RootComponents.Add<App>("#app");
builder.RootComponents.Add<HeadOutlet>("head::after");

builder.Services.AddScoped(sp => new HttpClient { BaseAddress = new Uri(builder.HostEnvironment.BaseAddress) });

builder.Services.AddMsalAuthentication(options =>
{
    builder.Configuration.Bind("AzureAd", options.ProviderOptions.Authentication);
    options.ProviderOptions.DefaultAccessTokenScopes.Add("api://backend-api-id/access_as_user");
});

await builder.Build().RunAsync();

// App.razor
<CascadingAuthenticationState>
    <Router AppAssembly="@typeof(App).Assembly">
        <Found Context="routeData">
            <AuthorizeRouteView RouteData="@routeData" DefaultLayout="@typeof(MainLayout)">
                <NotAuthorized>
                    <p>You are not authorized to access this page.</p>
                </NotAuthorized>
            </AuthorizeRouteView>
        </Found>
        <NotFound>
            <PageTitle>Not found</PageTitle>
            <p>Sorry, there's nothing at this address.</p>
        </NotFound>
    </Router>
</CascadingAuthenticationState>

// Pages/Dashboard.razor
@page "/dashboard"
@using Microsoft.AspNetCore.Authorization
@using Microsoft.AspNetCore.Components.WebAssembly.Authentication
@attribute [Authorize]
@inject HttpClient Http
@inject IAccessTokenProvider TokenProvider

<PageTitle>Dashboard</PageTitle>

<h2>Dashboard</h2>

@if (loading)
{
    <p>Loading...</p>
}
else if (data != null)
{
    <div class="stats">
        <div class="card">
            <h3>Orders</h3>
            <p>@data.Orders</p>
        </div>
        <div class="card">
            <h3>Revenue</h3>
            <p>$@data.Revenue</p>
        </div>
    </div>
}
else
{
    <p>Failed to load dashboard data.</p>
}

@code {
    private DashboardData? data;
    private bool loading = true;

    protected override async Task OnInitializedAsync()
    {
        try
        {
            var tokenResult = await TokenProvider.RequestAccessToken();
            if (tokenResult.TryGetToken(out var token))
            {
                Http.DefaultRequestHeaders.Authorization =
                    new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token.Value);

                data = await Http.GetFromJsonAsync<DashboardData>("api/dashboard");
            }
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Error loading dashboard: {ex.Message}");
        }
        finally
        {
            loading = false;
        }
    }

    public class DashboardData
    {
        public int Orders { get; set; }
        public decimal Revenue { get; set; }
    }
}

<style>
    .stats { display: flex; gap: 1rem; }
    .card { padding: 1rem; border: 1px solid #ccc; }
</style>

// Shared/LoginDisplay.razor
@using Microsoft.AspNetCore.Components.Authorization
@using Microsoft.AspNetCore.Components.WebAssembly.Authentication
@inject NavigationManager Navigation

<AuthorizeView>
    <Authorized>
        <span>Hello, @context.User.Identity?.Name!</span>
        <button class="nav-link btn btn-link" @onclick="BeginLogout">Log out</button>
    </Authorized>
    <NotAuthorized>
        <a href="authentication/login">Log in</a>
    </NotAuthorized>
</AuthorizeView>

@code{
    public void BeginLogout()
    {
        Navigation.NavigateToLogout("authentication/logout");
    }
}
```

**Explanation**: Blazor WebAssembly runs .NET in the browser, enabling C# for UI logic. Code sharing with backend (DTOs, validation logic). MSAL authentication integrates seamlessly. Best for .NET-heavy organizations wanting to leverage existing expertise. Trade-off: initial download size (~2-3MB compressed).

---

## Example 5: .NET MAUI Cross-Platform Mobile App

**Pattern**: .NET Multi-platform App UI (MAUI) with MVVM pattern, single codebase for iOS, Android, Windows, macOS.

**When to Use**: C#/.NET team, code sharing across mobile platforms, leveraging .NET libraries, native performance, Azure service integration.

```csharp
// MauiProgram.cs
using Microsoft.Extensions.Logging;
using CommunityToolkit.Maui;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .UseMauiCommunityToolkit()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
            });

        builder.Services.AddSingleton<IAuthService, AuthService>();
        builder.Services.AddSingleton<IDashboardService, DashboardService>();
        builder.Services.AddTransient<MainPage>();
        builder.Services.AddTransient<MainViewModel>();

#if DEBUG
        builder.Logging.AddDebug();
#endif

        return builder.Build();
    }
}

// App.xaml.cs
public partial class App : Application
{
    public App()
    {
        InitializeComponent();
        MainPage = new AppShell();
    }
}

// Services/AuthService.cs
public interface IAuthService
{
    Task<bool> LoginAsync(string email, string password);
    Task LogoutAsync();
    bool IsAuthenticated { get; }
    string? AccessToken { get; }
}

public class AuthService : IAuthService
{
    private readonly HttpClient _httpClient = new();
    private string? _accessToken;

    public bool IsAuthenticated => !string.IsNullOrEmpty(_accessToken);
    public string? AccessToken => _accessToken;

    public async Task<bool> LoginAsync(string email, string password)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync(
                "https://api.example.com/auth/login",
                new { email, password }
            );

            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadFromJsonAsync<LoginResponse>();
                _accessToken = result?.Token;
                await SecureStorage.SetAsync("auth_token", _accessToken);
                return true;
            }

            return false;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Login error: {ex.Message}");
            return false;
        }
    }

    public async Task LogoutAsync()
    {
        _accessToken = null;
        SecureStorage.Remove("auth_token");
        await Task.CompletedTask;
    }

    private record LoginResponse(string Token, string UserId);
}

// ViewModels/MainViewModel.cs
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

public partial class MainViewModel : ObservableObject
{
    private readonly IAuthService _authService;
    private readonly IDashboardService _dashboardService;

    [ObservableProperty]
    private string email = string.Empty;

    [ObservableProperty]
    private string password = string.Empty;

    [ObservableProperty]
    private bool isLoading;

    [ObservableProperty]
    private string? errorMessage;

    [ObservableProperty]
    private DashboardData? dashboardData;

    public MainViewModel(IAuthService authService, IDashboardService dashboardService)
    {
        _authService = authService;
        _dashboardService = dashboardService;
    }

    [RelayCommand]
    private async Task LoginAsync()
    {
        if (string.IsNullOrWhiteSpace(Email) || string.IsNullOrWhiteSpace(Password))
        {
            ErrorMessage = "Email and password are required";
            return;
        }

        IsLoading = true;
        ErrorMessage = null;

        try
        {
            var success = await _authService.LoginAsync(Email, Password);
            if (success)
            {
                await LoadDashboardAsync();
            }
            else
            {
                ErrorMessage = "Invalid credentials";
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Login failed: {ex.Message}";
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    private async Task LoadDashboardAsync()
    {
        IsLoading = true;
        try
        {
            DashboardData = await _dashboardService.GetDashboardDataAsync();
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Failed to load dashboard: {ex.Message}";
        }
        finally
        {
            IsLoading = false;
        }
    }
}

// Views/MainPage.xaml
<?xml version="1.0" encoding="utf-8" ?>
<ContentPage xmlns="http://schemas.microsoft.com/dotnet/2021/maui"
             xmlns:x="http://schemas.microsoft.com/winfx/2009/xaml"
             xmlns:vm="clr-namespace:MauiApp.ViewModels"
             x:Class="MauiApp.MainPage"
             x:DataType="vm:MainViewModel">

    <ScrollView>
        <VerticalStackLayout Padding="30,0" Spacing="25">
            <Label Text="Welcome to .NET MAUI" FontSize="32" HorizontalOptions="Center" />

            <Entry Text="{Binding Email}" Placeholder="Email" Keyboard="Email" />
            <Entry Text="{Binding Password}" Placeholder="Password" IsPassword="True" />

            <Button Text="Login" Command="{Binding LoginCommand}" IsEnabled="{Binding IsLoading, Converter={StaticResource InvertedBoolConverter}}" />

            <ActivityIndicator IsRunning="{Binding IsLoading}" IsVisible="{Binding IsLoading}" />

            <Label Text="{Binding ErrorMessage}" TextColor="Red" IsVisible="{Binding ErrorMessage, Converter={StaticResource IsNotNullConverter}}" />

            <StackLayout IsVisible="{Binding DashboardData, Converter={StaticResource IsNotNullConverter}}">
                <Label Text="Dashboard" FontSize="24" />
                <Label Text="{Binding DashboardData.Orders, StringFormat='Orders: {0}'}" />
                <Label Text="{Binding DashboardData.Revenue, StringFormat='Revenue: ${0:F2}'}" />
            </StackLayout>
        </VerticalStackLayout>
    </ScrollView>

</ContentPage>
```

**Explanation**: .NET MAUI provides single codebase for iOS, Android, Windows, macOS. MVVM pattern with CommunityToolkit.Mvvm simplifies data binding. Native performance via platform-specific compilation. Ideal for .NET teams wanting cross-platform reach with shared logic.

---

## Example 6: React Native Cross-Platform Mobile App

**Pattern**: React Native with TypeScript, React Navigation for routing, AsyncStorage for persistence, Expo for simplified tooling.

**When to Use**: JavaScript/TypeScript team, React web experience, fast iteration with hot reload, large ecosystem (npm packages), native module access.

```typescript
// App.tsx
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { AuthProvider } from './contexts/AuthContext';
import LoginScreen from './screens/LoginScreen';
import DashboardScreen from './screens/DashboardScreen';

export type RootStackParamList = {
  Login: undefined;
  Dashboard: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export default function App() {
  return (
    <AuthProvider>
      <NavigationContainer>
        <Stack.Navigator initialRouteName="Login">
          <Stack.Screen name="Login" component={LoginScreen} options={{ headerShown: false }} />
          <Stack.Screen name="Dashboard" component={DashboardScreen} />
        </Stack.Navigator>
      </NavigationContainer>
    </AuthProvider>
  );
}

// contexts/AuthContext.tsx
import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface AuthContextType {
  isAuthenticated: boolean;
  token: string | null;
  login: (email: string, password: string) => Promise<boolean>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [token, setToken] = useState<string | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    const loadToken = async () => {
      const storedToken = await AsyncStorage.getItem('auth_token');
      if (storedToken) {
        setToken(storedToken);
        setIsAuthenticated(true);
      }
    };
    loadToken();
  }, []);

  const login = async (email: string, password: string): Promise<boolean> => {
    try {
      const response = await fetch('https://api.example.com/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      if (response.ok) {
        const data = await response.json();
        setToken(data.token);
        setIsAuthenticated(true);
        await AsyncStorage.setItem('auth_token', data.token);
        return true;
      }

      return false;
    } catch (error) {
      console.error('Login error:', error);
      return false;
    }
  };

  const logout = async () => {
    setToken(null);
    setIsAuthenticated(false);
    await AsyncStorage.removeItem('auth_token');
  };

  return (
    <AuthContext.Provider value={{ isAuthenticated, token, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
};

// screens/LoginScreen.tsx
import React, { useState } from 'react';
import { View, Text, TextInput, Button, StyleSheet, ActivityIndicator } from 'react-native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAuth } from '../contexts/AuthContext';
import { RootStackParamList } from '../App';

type LoginScreenNavigationProp = NativeStackNavigationProp<RootStackParamList, 'Login'>;

interface Props {
  navigation: LoginScreenNavigationProp;
}

export default function LoginScreen({ navigation }: Props) {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async () => {
    if (!email || !password) {
      setError('Email and password are required');
      return;
    }

    setLoading(true);
    setError('');

    const success = await login(email, password);
    setLoading(false);

    if (success) {
      navigation.replace('Dashboard');
    } else {
      setError('Invalid credentials');
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Welcome</Text>
      <TextInput
        style={styles.input}
        placeholder="Email"
        keyboardType="email-address"
        autoCapitalize="none"
        value={email}
        onChangeText={setEmail}
      />
      <TextInput
        style={styles.input}
        placeholder="Password"
        secureTextEntry
        value={password}
        onChangeText={setPassword}
      />
      {error ? <Text style={styles.error}>{error}</Text> : null}
      {loading ? (
        <ActivityIndicator size="large" color="#0000ff" />
      ) : (
        <Button title="Login" onPress={handleLogin} />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', padding: 20 },
  title: { fontSize: 32, fontWeight: 'bold', marginBottom: 20, textAlign: 'center' },
  input: { height: 50, borderColor: '#ccc', borderWidth: 1, marginBottom: 15, paddingHorizontal: 10 },
  error: { color: 'red', marginBottom: 10 },
});

// screens/DashboardScreen.tsx
import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, ActivityIndicator, Button } from 'react-native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAuth } from '../contexts/AuthContext';
import { RootStackParamList } from '../App';

type DashboardScreenNavigationProp = NativeStackNavigationProp<RootStackParamList, 'Dashboard'>;

interface Props {
  navigation: DashboardScreenNavigationProp;
}

interface DashboardData {
  orders: number;
  revenue: number;
}

export default function DashboardScreen({ navigation }: Props) {
  const { token, logout } = useAuth();
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDashboard = async () => {
      try {
        const response = await fetch('https://api.example.com/dashboard', {
          headers: { Authorization: `Bearer ${token}` },
        });

        if (response.ok) {
          const dashboardData = await response.json();
          setData(dashboardData);
        }
      } catch (error) {
        console.error('Failed to load dashboard:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboard();
  }, [token]);

  const handleLogout = async () => {
    await logout();
    navigation.replace('Login');
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Dashboard</Text>
      {loading ? (
        <ActivityIndicator size="large" color="#0000ff" />
      ) : data ? (
        <View>
          <Text style={styles.stat}>Orders: {data.orders}</Text>
          <Text style={styles.stat}>Revenue: ${data.revenue}</Text>
        </View>
      ) : (
        <Text>Failed to load dashboard</Text>
      )}
      <Button title="Logout" onPress={handleLogout} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20 },
  title: { fontSize: 24, fontWeight: 'bold', marginBottom: 20 },
  stat: { fontSize: 18, marginBottom: 10 },
});
```

**Explanation**: React Native enables cross-platform mobile apps with JavaScript/TypeScript. React Navigation handles routing. AsyncStorage provides persistent storage. Expo simplifies builds and OTA updates. Best for teams with React web experience wanting mobile apps with shared component patterns.

---

## Framework Comparison Table

| Aspect                | React                                            | Angular                                                   | Vue.js                                                   | Blazor WebAssembly                              | .NET MAUI                                       | React Native                                              |
| --------------------- | ------------------------------------------------ | --------------------------------------------------------- | -------------------------------------------------------- | ----------------------------------------------- | ----------------------------------------------- | --------------------------------------------------------- |
| **Primary Use Case**  | Web SPA                                          | Web SPA                                                   | Web SPA                                                  | Web SPA                                         | Mobile (iOS/Android/Windows/macOS)              | Mobile (iOS/Android)                                      |
| **Language**          | JavaScript/TypeScript                            | TypeScript                                                | JavaScript/TypeScript                                    | C#                                              | C#                                              | JavaScript/TypeScript                                     |
| **Learning Curve**    | Moderate (JSX, hooks)                            | Steep (DI, RxJS, opinionated)                             | Gentle (progressive adoption)                            | Moderate (C#/Razor syntax)                      | Moderate (XAML, MVVM)                           | Moderate (React + native modules)                         |
| **Architecture**      | Flexible (choose your own)                       | Opinionated (modules, services, DI)                       | Flexible (progressive)                                   | Component-based with DI                         | MVVM with data binding                          | Component-based                                           |
| **State Management**  | Redux, Zustand, Context API                      | RxJS, Signals, Services                                   | Pinia, Vuex                                              | Cascading parameters, State service             | MVVM properties                                 | Context API, Redux, MobX                                  |
| **Ecosystem Size**    | Very Large (npm)                                 | Large (Angular CLI, RxJS)                                 | Large (Vue Router, Pinia)                                | Growing (.NET packages)                         | .NET ecosystem                                  | Very Large (npm, native modules)                          |
| **Performance**       | Fast (Virtual DOM, React 18 concurrent)          | Fast (Change Detection, Signals)                          | Fast (Virtual DOM, Composition API)                      | Good (WebAssembly, initial load 2-3MB)          | Native performance                              | Near-native (JavaScript bridge)                           |
| **Developer Pool**    | Very Large                                       | Large (enterprise focus)                                  | Large (growing)                                          | Growing (.NET developers)                       | .NET developers                                 | Large (React developers)                                  |
| **Azure Integration** | MSAL.js, Static Web Apps                         | MSAL Angular, Static Web Apps                             | MSAL, Static Web Apps                                    | MSAL, Authentication component                  | Azure SDKs                                      | Azure SDKs, MSAL React Native                             |
| **Build Size**        | Small (React: ~40KB min+gzip)                    | Medium (Angular: ~100KB min+gzip)                         | Small (Vue: ~34KB min+gzip)                              | Large (2-3MB compressed first load)             | Native binary (~10-20MB APK)                    | Native binary (~15-25MB APK)                              |
| **Testing**           | Jest, React Testing Library                      | Jasmine, Karma, Jest                                      | Vitest, Vue Test Utils                                   | bUnit, xUnit, Playwright                        | xUnit, NUnit                                    | Jest, React Native Testing Library                        |
| **Best For**          | Reusable components, large dev pool, flexibility | Enterprise apps, strong typing, long-term maintainability | Incremental adoption, gentle learning curve, flexibility | .NET teams, code sharing frontend/backend       | .NET teams, cross-platform mobile, code sharing | React teams, cross-platform mobile, fast iteration        |
| **Trade-Offs**        | More decisions (state, routing, patterns)        | Steep learning curve, verbose boilerplate                 | Smaller enterprise adoption vs React/Angular             | Large initial download, .NET runtime in browser | XAML learning curve, smaller dev pool           | JavaScript bridge perf overhead, native module complexity |
