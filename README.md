[![GitHub Release](https://img.shields.io/github/v/release/commandlinecoding/elephant?style=flat-square&color=blue)](https://github.com/commandlinecoding/elephant/releases)
[![Docker Pulls (Docker Hub)](https://img.shields.io/docker/pulls/commandlinecoding/elephant?style=flat-square&logo=docker)](https://hub.docker.com/r/commandlinecoding/elephant)
[![Go Integration & Test Suite](https://github.com/commandlinecoding/elephant/actions/workflows/backend.yaml/badge.svg)](https://github.com/commandlinecoding/elephant/actions)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL-green.svg?style=flat-square)](LICENSE)

---

# Elephant
Elephant – a privacy-first, open-source messaging application made with Go and Flutter. Elephant supports secure authentication, user discovery, and real-time chat over WebSocket, with all communication TLS-protected between client and server.

<img src="./mobile/assets/launcher/elephant.png" width="200" height="200" alt="App Screenshot">

 ## Tech Stack
 
| Layer | Technology |
|---|---|
| Backend | Go (chi, pgx, gorilla/websocket, golang-jwt, argon2) |
| Mobile | Flutter (http, web_socket_channel, provider, sqflite) |
| Database | PostgreSQL 16 |
| CI/CD | GitHub Actions, Docker Compose, GHCR |

## GitHub Releases (Mobile Apps)

If you just want to run the client application or get a production-ready backend binary without setting up a build environment, head straight over to our **[GitHub Releases Page](https://github.com/commandlinecoding/elephant/releases)**.

Here you will find:
* **Client Installers:** Pre-built application packages (`.apk` for Android ) ready for deployment.
---

## Quick Start (Docker/Podman)

The fastest way to run Elephant is by pulling the published image — no Go toolchain required.

#### Pulling image from Docker Hub
```bash
docker run --name elephant-server \
  -e PORT=3000 \
  -e POSTGRES_HOST=host.docker.internal \
  -e POSTGRES_PORT=3000 \
  -e POSTGRES_USER=your_db_user \
  -e POSTGRES_PASSWORD=your_db_password \
  -e POSTGRES_DB=your_db_name \
  -e JWT_SECRET=a_secure_32_character_secret_key_phrase \
  -p 3000:3000 \
  -d commandlinecoding/elephant:latest
 ```

#### Pulling image from Github GHCR
```bash
podman run --name elephant-server \
  -e PORT=3000 \
  -e POSTGRES_HOST=host.containers.internal \
  -e POSTGRES_PORT=3000 \
  -e POSTGRES_USER=your_db_user \
  -e POSTGRES_PASSWORD=your_db_password \
  -e POSTGRES_DB=your_db_name \
  -e JWT_SECRET=a_secure_32_character_secret_key_phrase \
  -p 3000:3000 \
  -d ghcr.io/commandlinecoding/elephant:latest
```


Once running, verify the server is healthy:

```bash
curl http://HOST:PORT/api/health
```
 
You should see:
 
```json
{"success":true,"data":{"postgres":"up","timestamp":"..."}}
```

## Local Development Setup
 
If you're contributing to the backend and want to build from source instead of pulling the published image, use the dev compose override:


```bash
# Clone the repo for the compose file and .env template
git clone https://github.com/commandlinecoding/elephant.git
cd elephant
 
# Copy and fill in environment variables
cp .env.example .env
 
# Start the stack
docker compose up -d
# or: podman-compose up -d
```
 
This builds the `server` image from `server/Dockerfile` on every run instead of pulling from GHCR, so your local changes are reflected immediately.
 
### Running the backend without Docker
 
```bash
cd server
go mod download
go run main.go
```
 
Make sure PostgreSQL is running and reachable using the values in your `.env` file (`POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`).
 
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
|`GOOGLE_CLIENT_ID`| Google OAuth client ID| — |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secrett | — |
| `GOOGLE_REDIRECT_URL` | Google OAuth redirect callback URL | `http://HOST:PORT/api/auth/google/callback` |
| `GITHUB_CLIENT_ID` | GitHub OAuth client ID | — |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth client secret | — |
| `GITHUB_REDIRECT_URL` | GitHub OAuth redirect callback URL | `http://HOST:PORT/api/auth/github/callback` |

 
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
HOST=$HOST PORT=$PORT go test -v ./tests/...
```

### CI/CD
 
Docker images are built and published to both GHCR and Docker Hub automatically on every version tag push.
Android APKs are built and attached to GitHub Releases automatically on every version tag push.

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
│   ├── services/            # Business logic (auth, users, JWT, WebSocket)
│   ├── tests/               # Integration tests
│   └── Dockerfile
├── compose.yaml              # Default: pulls published image
├── compose.dev.yaml          # Override: builds server from source
├── .env.example              # Environment variable template
└── LICENSE
```

## Contributing

Checkout [CONTRIBUTING.md](CONTRIBUTING.md) for more information

## License
 
See [LICENSE](LICENSE) for details.
