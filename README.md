# Elephant
Elephant – a privacy-first, open-source messaging application made with Go and Flutter. Elephant supports secure authentication, user discovery, and real-time chat over WebSocket, with all communication TLS-protected between client and server.

## Quick Start (Docker/Podman)

The fastest way to run Elephant is by pulling the published image — no Go toolchain required.

```bash
# Log in to GitHub Container Registry 
docker login ghcr.io -u YOUR_GITHUB_USERNAME
# or: podman login ghcr.io -u YOUR_GITHUB_USERNAME
 
# Clone the repo for the compose file and .env template
git clone https://github.com/commandlinecoding/elephant.git
cd elephant
 
# Copy and fill in environment variables
cp .env.example .env
 
# Start the stack
docker compose up
# or: podman-compose up
```
Once running, verify the server is healthy:
 
```bash
curl http://localhost:8080/api/health
```
 
You should see:
 
```json
{"success":true,"data":{"postgres":"up","timestamp":"..."}}
```

 ## Tech Stack
 
| Layer | Technology |
|---|---|
| Backend | Go (chi, pgx, gorilla/websocket, golang-jwt, argon2) |
| Mobile | Flutter (http, web_socket_channel, provider, sqflite) |
| Database | PostgreSQL 16 |
| CI/CD | GitHub Actions, Docker Compose, GHCR |

## Local Development Setup
 
If you're contributing to the backend and want to build from source instead of pulling the published image, use the dev compose override:
 
```bash
docker compose -f compose.yaml -f compose.dev.yaml up
```
 
This builds the `server` image from `server/Dockerfile` on every run instead of pulling from GHCR, so your local changes are reflected immediately.
 
### Running the backend without Docker
 
```bash
cd server
go mod download
go run main.go
```
 
Make sure PostgreSQL is running and reachable using the values in your `.env` file (`POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`).
 
### Running database migrations
 
```bash
cd server
psql "postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB" \
  -f migrations/001_create_users_up.sql \
  -f migrations/002_create_refresh_tokens_up.sql \
  -f migrations/003_add_search_indexes_up.sql \
  -f migrations/004_create_message_up.sql
```
 
### Running the mobile app
 
```bash
cd mobile
flutter pub get
flutter run
```

## Environment Variables
 
| Variable | Description | Default |
|---|---|---|
| `HOST` | Server bind address | `127.0.0.1` |
| `PORT` | Server port | `3000` |
| `POSTGRES_USER` | Database username | `postgres` |
| `POSTGRES_PASSWORD` | Database password | — |
| `POSTGRES_DB` | Database name | `myapi_db` |
| `POSTGRES_PORT` | Database port | `5432` |
| `POSTGRES_HOST` | Database host | `localhost` |
| `JWT_SECRET` | Secret key for signing JWTs | — |
| `ARGON_MEMORY` | Argon2id memory cost (KB) | `65536` |
| `ARGON_ITERATIONS` | Argon2id iteration count | `3` |
| `ARGON_PARALLELISM` | Argon2id parallelism degree | `2` |
 
See `.env.example` for a starting template.


## API

Checkout the [API document](docs/API_CONTRACTS.md)

### Registration note
 
Usernames are normalized to lowercase and assigned a random 4-digit discriminator on registration to avoid collisions, e.g. registering as `abc` may result in the stored username `abc.4821`. Use the full discriminated username returned in the registration response when logging in.

## Testing
 
Run the full backend test suite (unit + integration):
 
```bash
cd server
go vet ./...
go test -v ./...
```
 
Integration tests under [server/tests/](server/tests/) expect a running server and database. Start the stack first, then run:
 
```bash
HOST=localhost PORT=8080 go test -v ./tests/...
```

### CI/CD
 
Tests, `go vet`, and `staticcheck` run automatically on every push and pull request via GitHub Actions (`.github/workflows/`). Docker images are built and published to GHCR via manual `workflow_dispatch` or on tagged pushes.

## Project Structure
 
```
elephant/
├── .github/                 # GitHub Actions workflows
├── docs/                    # Project documentation
├── mobile/                  # Flutter client
│   ├── android/
│   ├── ios/
│   ├── lib/
│   ├── assets/
│   ├── pubspec.yaml
│   └── README.md
├── server/                  # Go backend
│   ├── config/              # DB, JWT, Argon2, CORS configuration
│   ├── controllers/         # HTTP handlers
│   ├── env/                 # Environment variable loading
│   ├── errors/              # Sentinel error definitions
│   ├── middlewares/         # Auth, CORS, logging, rate limiting
│   ├── migrations/          # SQL migration files
│   ├── models/              # Data models
│   ├── repository/          # Database access layer
│   ├── routes/              # Route definitions
│   ├── services/            # Business logic (auth, users, JWT, WebSocket hub)
│   ├── tests/               # Integration tests
│   └── Dockerfile
├── compose.yaml              # Default: pulls published image
├── compose.dev.yaml          # Override: builds server from source
├── .env.example              # Environment variable template
└── LICENSE
```

## License
 
See [LICENSE](LICENSE) for details.
