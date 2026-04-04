# Blazor Model Comparison: Server vs WASM

## Current Architecture: Blazor Server

```
Browser ──SignalR WebSocket──▶ Blazor Server (renders UI + calls API)──HTTP──▶ ASP.NET API ──▶ MongoDB
```
### Typical folder structure

```
src/
  apps/
    frontend-blazor/ ← Blazor Server project (UI + SignalR)
    api-aspnet/ ← ASP.NET API project
```

- **1 server project** (`frontend-blazor`) — does everything
- Services like `SeriesService` use `HttpClientFactory` server-side to call the API
- Auth tokens live in server memory (`ClientAuthState`)
- Browser gets only DOM diffs over WebSocket

---

## Option A: Blazor WebAssembly (Standalone)

```
Browser (.NET WASM runtime + your app) ──HTTP──▶ ASP.NET API ──▶ MongoDB
                                        ──HTTP──▶ Static file host (CDN/S3/nginx)
```
### Sample folder structure

```
src/
  apps/
    frontend-blazor/    ← Client (WASM) project
  api-aspnet/           ← ASP.NET API project
```

### What changes

| Area | Now (Server) | WASM Standalone |
|---|---|---|
| **SDK** | `Microsoft.NET.Sdk.Web` | `Microsoft.NET.Sdk.BlazorWebAssembly` |
| **Program.cs** | `WebApplication.CreateBuilder` | `WebAssemblyHostBuilder.CreateDefault` |
| **Render mode** | `.AddInteractiveServerComponents()` | Gone — everything runs in browser |
| **HttpClient** | `IHttpClientFactory` (server-side) | `HttpClient` injected directly, calls API via **CORS** |
| **Auth** | Server-side `ClientAuthState` | Browser `localStorage` for JWT + custom `AuthenticationStateProvider` |
| **Hosting** | ASP.NET Kestrel server | **Static files** — any CDN, S3 bucket, nginx, Cloud Run, GitHub Pages |
| **Data Protection** | Key ring on disk | Gone — no server-side state |
| **ReconnectModal** | Needed (SignalR drops) | Gone — no connection to drop |

### Example Program.cs

```csharp
var builder = WebAssemblyHostBuilder.CreateDefault(args);
builder.RootComponents.Add<App>("#app");

builder.Services.AddScoped(sp => new HttpClient 
{ 
    BaseAddress = new Uri("https://your-api-url") 
});
builder.Services.AddAuthorizationCore();
// same service registrations, but they run IN THE BROWSER

await builder.Build().RunAsync();
```

**Key implication**: The `SeriesService`, `AuthService`, and `UsersService` already use `HttpClient` to call the API — they'd work almost unchanged. The main rework is auth (move JWT to `localStorage`) and removing server-side concerns (data protection, reconnect UI).

---

## Option B: WASM Hosted

```
Browser (.NET WASM runtime + your app) ──HTTP──▶ ASP.NET Host (serves WASM files + proxies/is the API) ──▶ MongoDB
```

### Sample folder structure

This is WASM Standalone + a server project that serves the WASM files and hosts the API. You'd get a 3-project solution:

```
src/
  apps/
    frontend-blazor/              ← Client (WASM) project
    frontend-blazor.Server/       ← Server project (hosts WASM + could BE the API)
    api-aspnet/                   ← Existing API (could merge into Server)
```

The server project adds one line:

```csharp
app.UseBlazorFrameworkFiles();
app.MapFallbackToFile("index.html");
```

### What changes

| Area | WASM Standalone | WASM Hosted |
|---|---|---|
| **Project structure** | 1 project (client) | 2 or 3 projects (client + server + optional API) |
| **SDK** | `Microsoft.NET.Sdk.BlazorWebAssembly` | Client: `Microsoft.NET.Sdk.BlazorWebAssembly`<br>Server: `Microsoft.NET.Sdk.Web` |
| **Program.cs (client)** | `WebAssemblyHostBuilder.CreateDefault` | Same as Standalone |
| **Program.cs (server)** | N/A | `WebApplication.CreateBuilder` + `app.UseBlazorFrameworkFiles()` + `app.MapFallbackToFile("index.html")` |
| **HttpClient** | Injected in browser, calls API via CORS | Injected in browser, calls API via same origin (no CORS needed) |
| **Auth** | Browser `localStorage` for JWT | Can use cookies (server issues auth cookie to browser) or localStorage |
| **Hosting** | Static files (CDN/S3/nginx) + API | Server hosts both WASM files and API (single deployment) |
| **CORS** | Required on API | Not needed (same origin) |
| **Deployment** | Separate static host and API | Single serverless/container app or K8s pod |

**Key implication**: WASM Hosted simplifies deployment (one server hosts both WASM and API, no CORS headaches) and enables cookie-based auth if desired. The client code is nearly identical to Standalone, but the server project adds a few lines to serve the WASM files and fallback to `index.html`.

---

## Tradeoff Summary

| | Server (current) | WASM / WASM Hosted |
|---|---|---|
| **Cloud Run compatible** | No (WebSocket) | Yes — static files or simple HTTP |
| **Scale to zero** | No (kills connections) | Yes — no persistent connections |
| **Offline capable** | No | Possible with service workers |
| **Server resources** | UI rendering burns CPU | Zero — browser does all rendering |
| **Initial load** | Fast (tiny HTML) | Slower (~5-10MB .NET WASM download, then cached) |
| **Latency feel** | Every click = round trip | Instant UI, only API calls have latency |

---

## Migration Effort Estimate

**Low-medium.** The existing services already use the HttpClient → API pattern, which is exactly how WASM apps work. Main changes:

1. Swap SDK and `Program.cs` bootstrap (~30 min)
2. Move auth from server memory to browser `localStorage` (~2-4 hrs)
3. Remove `ReconnectModal`, data protection, SignalR config
4. Add CORS to the API (or use WASM Hosted to avoid it)
5. Test everything in-browser

---

## Kubernetes Scaling Considerations

**Blazor Server is the better fit for Kubernetes** — and it's what this project uses.

| Concern | Blazor Server on K8s | Blazor WASM on K8s |
|---|---|---|
| **What K8s runs** | The frontend server (renders UI, holds connections) | Just a static file server (nginx) — almost no work |
| **Scaling model** | Scale pods to handle more concurrent users | Nothing to scale — browser does the work |
| **Session affinity** | Required (sticky sessions via ingress) — already configured | Not needed |
| **State management** | Server memory per-connection — simple | Browser `localStorage` — requires rethinking auth |
| **Complexity** | 1 container, already working | Need CORS config or a reverse proxy, plus auth rework |

### What are you scaling?

- **The API** is the bottleneck that benefits from K8s horizontal scaling (multiple pods behind a service, load balanced). This is identical in both models.
- **Blazor Server frontend** benefits from K8s scaling if you have many concurrent users (each holds a SignalR connection consuming ~250KB RAM). For a course project, a single replica is more than enough.
- **Blazor WASM frontend** on K8s is overkill — you're just serving static files. A CDN or S3 bucket would be cheaper and faster.

### Recommendation

**Stay with Blazor Server.** The current setup — Blazor Server + ASP.NET API on K8s with ingress sticky sessions — is the architecture that actually demonstrates Kubernetes scaling concepts (replica sets, load balancing, session affinity, health probes). Converting to WASM would remove the need for K8s on the frontend entirely, which makes the project less interesting from a K8s perspective.

WASM only wins if you need **serverless/scale-to-zero** (Cloud Run, Azure Container Apps) or want to eliminate the frontend server cost entirely. On a Kubernetes cluster you already have, that's not a concern.

---

## Serverless Deployment Considerations (Cloud Run, AWS Fargate, Azure Container Apps)

For serverless platforms like Google Cloud Run or AWS Fargate, **Blazor WebAssembly (WASM) or WASM Hosted** is the best fit.

### Why?
- **Serverless platforms** (Cloud Run, Fargate, Azure Container Apps) are designed for stateless, short-lived HTTP workloads. They do not support persistent WebSocket connections or session affinity, which Blazor Server requires.
- **Blazor WASM** runs entirely in the browser. The server only needs to serve static files (WASM, JS, HTML) and provide an API. This matches the stateless, scale-to-zero model of serverless.
- **WASM Hosted** (Blazor WASM + ASP.NET API in one project) also works well: the serverless container serves both the static files and the API, with no need for sticky sessions or long-lived connections.

### Summary Table

| Platform         | Blazor Server | Blazor WASM / WASM Hosted |
|------------------|:-------------:|:------------------------:|
| Cloud Run        | 🚫 Not suitable (needs WebSocket, sticky sessions) | ✅ Perfect fit (stateless HTTP) |
| AWS Fargate      | 🚫 Not suitable | ✅ Perfect fit |
| Azure Container Apps | 🚫 Not suitable | ✅ Perfect fit |

**Recommendation:**  
If you want to deploy to Cloud Run, Fargate, or any serverless container platform, convert your frontend to Blazor WASM or WASM Hosted. This architecture is stateless, scales to zero, and works with any HTTP-based hosting.

### Typical folder structure

```
src/
  apps/
    frontend-blazor/    ← Blazor Server project (UI + SignalR)
  api-aspnet/           ← ASP.NET API project
```
