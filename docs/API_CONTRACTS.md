# Elephant Messenger API Contracts - v0.1.0

## Global Requirements & Configuration

- **Base URL:** `http://HOST:PORT` (Local Sandbox)
- **Default Content-Type:** `application/json`
- **Authorization:** `Bearer <access_token>`
- **Timestamp Format:** `ISO8601 UTC`
---

## Health Endpoint

Evaluates the operational status of the server application and its upstream resource dependencies (such as the PostgreSQL database pool).

- **URL:** `/api/health`
- **Method:** `GET`
- **Authentication Required:** `NO`
- **curl:** `curl -X GET http://HOST:PORT/api/health \ -s | jq .`

### Expected Responses

#### `200 OK` (System operational)

Returned when the server runtime is healthy and can successfully execute a ping query against the database.

```json
{
  "success": true,
  "data": {
    "postgres": "up",
    "timestamp": "<time>"
  }
}
```

#### `500 Internal Server Error`

Returned when the server has encountered an unexpected error (error description provided)

```json
{
  "success": false,
  "data": {
    "postgres": "down",
    "timestamp": "<time>"
  },
  "error": "Database engine unreachable"
}
```

## Authentication Endpoints

### 1. Register User

- **URL:** `/api/auth/register`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `NO`
- **curl:** `curl -X POST http://HOST:PORT/api/auth/register \ -H "Content-Type: application/json" \ -d '{ "username": "<username>", "display_name": "Full Name", "password": "<password>" }' \ -s | jq .`

#### Request Body

```json
{
  "username": "<username>",
  "display_name": "Full Name",
  "password": "<password>"
}
```

#### Note

The username in the response may differ from the one submitted. If the requested username is already taken, the server automatically appends a numeric suffix (e.g. "abc" → "abc.4130") to ensure uniqueness.

#### Expected Responses

##### `201 Created` (User Created Successfully)

Returned when the account/user is successfully created

```json
{
  "success": true,
  "data": {
    "tokens": {
      "access_token": "<access_token>",
      "refresh_token": "<refresh_token>"
    },
    "user": {
      "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "username": "<username>",
      "display_name": "Full Name",
      "created_at": "<created_time>"
    }
  }
}
```

##### `400 Bad Request`

Returned when the json does not contain valid payload (error description provided)

```json
{
  "success": false,
  "error": "Invalid payload syntax"
}
```

### 2. Login User

- **URL:** `/api/auth/login`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `NO`
- **curl:** `curl -X POST http://HOST:PORT/api/auth/login \ -H "Content-Type: application/json" \ -d '{ "username": "<username>", "password": "<password>" }' \ -s | jq .`

#### Request Body

```json
{
  "username": "<username>",
  "password": "<password>"
}
```

#### Expected Response

##### `200 OK` (Login Successful)

Returned when User has successfully logged in

```json
{
  "success": true,
  "data": {
    "tokens": {
      "access_token": "<access_token>",
      "refresh_token": "<refresh_token>"
    },
    "user": {
      "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "username": "<username>",
      "display_name": "Full Name",
      "created_at": "<created_time>"
    }
  }
}
```

##### `401 Unauthorized`

Returned when credentials are incorrect

```json
{
  "success": false,
  "error": "invalid username or password credentials"
}
```

##### `400 Bad Request`

Returned when json payload structure is incorrect

```json
{
  "success": false,
  "error": "Invalid json payload structure"
}
```

### 3. Refresh

- **URL:** `/api/auth/refresh`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `NO`
- **curl:** `curl -X POST http://HOST:PORT/api/auth/refresh \ -H "Content-Type: application/json" \ -d '{ "refresh_token": "<refresh_token>" }' \ -s | jq .`

#### Request Body

```json
{
  "refresh_token": "<refresh_token>"
}
```

#### Expected Response

##### `200 OK` (Token Refresh Successful)

Returned when token is refreshed successfully

```json
{
  "success": true,
  "data": {
    "access_token": "<access_token>",
    "refresh_token": "<refresh_token>"
  }
}
```

##### `401 Unauthorized`

Returned when refresh token given is invalid

```json
{
  "success": false,
  "error": "refresh token expired or revoked"
}
```

## Search Endpoints

### 1. User ME

Get user data

- **URL:** `/api/users/me`
- **Method:** `GET`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X GET "http://HOST:PORT/api/users/me" \ -H "Authorization: Bearer <access_token>"`

#### Expected Responses

##### `200 OK`

Returned when user data is successfully retrieved

```json
{
  "success": true,
  "data": {
    "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "username": "<username>",
    "display_name": "Full Name",
    "created_at": "<created_time>"
  }
}
```

##### `401 Unauthorized`

Returned when access token is missing, expired or wrong

```json
{
  "success": false,
  "error": "Access token missing, expired or malformed"
}
```

### 2. Search user by ID

Used to find user with user id
Get user data

- **URL:** `/api/users/{id}`
- **Method:** `GET`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X GET "http://HOST:PORT/api/users/{id}" \ -H "Authorization: Bearer <access_token>"`

#### Expected Responses

##### `200 OK`

Returned when user is successfully found

```json
{
  "success": true,
  "data": {
    "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "username": "<username>",
    "display_name": "Full name",
    "created_at": "<created_time>"
  }
}
```

##### `404 Not Found`

Returned when user is not found or user id is incorrect

```json
{
  "success": false,
  "error": "Requested profile does not exist"
}
```

##### `401 Unauthorized`

Returned when access token is missing or expired or incorrect

```json
{
  "success": false,
  "error": "Access token missing, expired or malformed"
}
```

### 3. Search User by username and display name

Used to find user by username and display name
Get user data

- **URL:** `/api/users/search?q={username}&page={page}&limit={limit}`
- **Method:** `GET`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X GET "http://HOST:PORT/api/users/search?q={name}&page={page}&limit={limit}" \ -H "Authorization: Bearer <access_token>"`

#### Expected Responses

##### `200 OK`

Returned when user is successfully found

```json
{
  "success": true,
  "data": [
    {
      "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "username": "<username>",
      "display_name": "Full Name",
      "created_at": "<created_time>"
    },
    {
      "id": "bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb",
      "username": "<username>",
      "display_name": "Full Name",
      "created_at": "<created_time>"
    }
  ]
}
```

`NOTE:` If no users are found

```json
{
  "success": true,
  "data": []
}
```

##### `401 Unauthorized`

Returned when access token is missing or expired or incorrect

```json
{
  "success": false,
  "error": "Access token missing, expired or malformed"
}
```

##### `500 Internal Server Error`

Returned when search has failed to execute

```json
{
  "success": false,
  "error": "Failed to execute user directory search operations"
}
```

## WebSocket Endpoints

Connect to websocket

- **URL:** `/api/ws?token={access_token}`
- **Method:** `WS (websocket Upgrade)`
- **Headers:** `NONE`
- **Authentication Required:** `YES`
- **wscat:** `wscat -c "ws://HOST:PORT/api/ws?token={access_token}"`

### Expected Response

#### `101 Switching Protocols`

Returned when websocket is successfully connected

```
connected to ws://HOST:PORT/api/ws?token={access_token}
```

#### `Unexpected server response: 404`

Returned when access token is expired or incorrect

```
WebSocket error: Unexpected server response: 404
```

## Messages Endpoints

### 1. Send Message

- **URL:** `/api/messages/`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X POST "http://HOST:PORT/api/messages/" \ -H "Content-Type: application/json" \ -H "Authorization: Bearer <access_token>" \ -d '{ "receiver_id": "<receiver_id>", "content": "<content>" }'`

#### Request Body

```json
{
  "receiver_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "content": "<content>"
}
```

#### Expected Response

##### `201 Created`

Returned when message is successfully sent

```json
{
  "success": true,
  "data": {
    "id": "cccccccc-cccc-cccc-cccc-cccccccccccc",
    "sender_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "receiver_id": "bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb",
    "content": "<content>",
    "created_at": "<created_time>"
  }
}
```

##### `401 Unauthorized`

Returned when access token is expired or incorrect

```json
{
  "success": false,
  "error": "Access token missing, expired or malformed"
}
```

### 2. Message History

To get message history with specific user using user id

- **URL:** `/api/users/messages/?with={receiver_id}&before={time}&limit={limit}`
- **Method:** `GET`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X GET "http://HOST:PORT/api/messages/?with={receiver_id}&before={time}&limit={limit}" \ -H "Authorization: Bearer <access_token>"`

#### Expected Response

##### `200 OK`

Returned when data is successfully retrieved

```json
{
  "success": true,
  "data": [
    {
      "id": "cccccccc-cccc-cccc-cccc-cccccccccccc",
      "sender_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "receiver_id": "bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb",
      "content": "<content>",
      "created_at": "<created_time>"
    }
  ]
}
```

##### `401 Unauthorized`

Returned when access token is expired or incorrect

```json
{
  "success": false,
  "error": "Access token missing, expired or malformed"
}
```
