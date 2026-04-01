## Live Frontend URL

> Harlan Coben Series URL: (https://harlan-coben-series.netlify.app/)

---

## API Integration Details

This frontend integrates with a backend API. The API endpoints are defined in the `.env.development` and `.env.production` files. All non-GET and `/auth` requests are made using fetch and are protected by authentication (see `src/context/AuthContext.jsx`).

**API endpoints:**
- Series: `/api/series` (CRUD operations)
- Users: `/api/users` (CRUD operations)
- Auth: `/api/auth` (login, register)

**Integration:**
- The frontend uses context and protected routes to manage authentication and API access.
- See `src/pages/` for main page logic and `src/components/` for UI components.

---

## Setup Instructions for Local Development

1. **Clone the repository:**
	```bash
	git clone <repo-url>
	cd assignment3-frontend-darrenmartell
	```

2. **Install dependencies:**
	```bash
	pnpm install
	```

3. **Start the local development server:**
	```bash
	pnpm run dev
	```

4. **Configure API endpoints:**
	- Edit the `.env.development` and `.env.production` files to point to your local or remote API server.

---

## Additional Notes

- For authentication and protected routes, see `src/context/AuthContext.jsx` and `src/routes/ProtectedRoute.jsx`.

## Blazor Migration

- Migration prompts live in `.github/prompts/`.
- Migration planning and gate documentation live in `docs/blazor-migration/`.
- The existing solution already expects the Blazor project at `blazor-migration/BlazorMigration.csproj`.
