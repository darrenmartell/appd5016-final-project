## Live Frontend URL

Add your deployed frontend URL here (e.g., https://harlan-coben-series.netlify.app/)

## API Integration Details

This project exposes a REST API for managing Harlan Coben series and site users. The API endpoints include:

- `/users` (GET, DELETE)
- `/series` (GET, POST, PUT, PATCH, DELETE)
- Authentication endpoints under `/auth` (login, register)

All non-GET and `/auth` endpoints require proper authentication using JWT for protected routes.

Example integration (using fetch):

```ts
  const response = await fetch(`${config.API_URL}/series/${id}`, {
    method: 'DELETE',
    headers: { 
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
  })
```

## Setup Instructions for Local Development

1. **Clone the repository:**
	```sh
	git clone <repo-url>
	cd assignment2-restapi-darrenmartell
	```
2. **Install dependencies:**
	```sh
	pnpm install
	```
3. **Configure environment variables:**
	- Create a `.env` file in the root directory.
	- Add MongoDB URI, JWT secret, and other required variables.
4. **Run the development server:**
	```sh
	pnpm start:dev
	```
5. **Access the API:**
	- The API will be available at `http://localhost:3000` by default.

For more details, see the [DEPLOYMENT.md](DEPLOYMENT.md) file.
