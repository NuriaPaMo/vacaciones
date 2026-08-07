# ─── Build stage ──────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
WORKDIR /src

# Copy solution and project files first for layer-cache efficiency
COPY ["src/backend/VacationManagement.sln", "./"]
COPY ["src/backend/src/", "src/"]
COPY ["src/backend/tests/", "tests/"]

RUN dotnet restore "src/Api/VacationManagement.Api.csproj" --runtime linux-musl-x64

COPY . .

RUN dotnet publish "src/Api/VacationManagement.Api.csproj" \
    --configuration Release \
    --runtime linux-musl-x64 \
    --self-contained false \
    --output /app/publish \
    -p:PublishSingleFile=false \
    -p:TreatWarningsAsErrors=true

# ─── Runtime stage ────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS runtime
WORKDIR /app

# Security hardening — non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# OTel auto-instrumentation agent is injected by Container Apps via sidecar — not bundled here

COPY --from=build --chown=appuser:appgroup /app/publish .

EXPOSE 8080

ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production
ENV DOTNET_EnableDiagnostics=0

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:8080/health/live || exit 1

ENTRYPOINT ["dotnet", "VacationManagement.Api.dll"]
