# Elephant Messenger API Contracts - v0.1.0

## Global Requirements & Configuration
* **Base URL:** `http://HOST:PORT` (Local Sandbox)
* **Default Content-Type:** `application/json`
* **Authorization:** `Bearer <access_token>`
---

## Health Endpoint
Evaluates the operational status of the server application and its upstream resource dependencies (such as the PostgreSQL database pool). 
* **URL:** `/api/health`
* **Method:** `GET`
* **Authentication Required:** `NO`
* **curl:** `curl -X GET http://HOST:PORT/api/health \ -s | jq .`

### Expected Responses

#### `200 OK` (System operational)
Returned when the server runtime is healthy and can successfully execute a ping query against the database.
```json
{
  "success": true,
  "data": {
    "postgres": "up",
    "timestamp": "2026-06-23T17:35:39.5768732Z"
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
    "timestamp": "2026-06-23T17:48:13.5365069Z"
  },
  "error": "Database engine unreachable"
}
```

## Authentication Endpoints

### 1. Register User
* **URL:** `/api/auth/register`
* **Method:** `POST`
* **Headers:** `Content-Type: application/json`
* **Authentication Required:** `NO`
* **curl:** `curl -X POST http://HOST:PORT/api/auth/register \ -H "Content-Type: application/json" \ -d '{
    "username": "abc",
    "display_name": "abc",
    "password": "SecurePassword123!"
  }' \ -s | jq .`

#### Request Body
```json
{
  "username": "abc.4130",
  "display_name": "abc.7117",
  "password": "SecurePassword123!"
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
      "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3ODIyMzk5NjgsImlhdCI6MTc4MjIzOTA2OCwic3ViIjoiNTJmNDJlNTYtM2M4MC00N2IxLWJiMDUtNTU5YzhmY2Y0Y2ViIn0.Zm-375NuAWYlwIiI4dR4eLbbWt6VvtPBgnXy1xnQWfQ",
      "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3ODI4NDM4NjgsImlhdCI6MTc4MjIzOTA2OCwic3ViIjoiNTJmNDJlNTYtM2M4MC00N2IxLWJiMDUtNTU5YzhmY2Y0Y2ViIn0.k6SjVY6dPW8C3PZSDAItuhdiXMThwbu1kubX3AWquKs"
    },
    "user": {
      "id": "52f42e56-3c80-47b1-bb05-559c8fcf4ceb",
      "username": "abc.4130",
      "display_name": "abc.7118",
      "created_at": "2026-06-23T23:54:28.51477+05:30"
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
* **URL:** `/api/auth/login`
* **Method:** `POST`
* **Headers:** `Content-Type: application/json`
* **Authentication Required:** `NO`
* **curl:** `curl -X POST http://HOST:PORT/api/auth/login \ -H "Content-Type: application/json" \ -d '{
    "username": "abc.4130",
    "password": "SecurePassword123!"
  }' \ -s | jq .`

#### Request Body
```json
{
  "username": "abc.4130",
  "password": "SecurePassword123!"
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
      "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3ODIyNDExMzIsImlhdCI6MTc4MjI0MDIzMiwic3ViIjoiNTJmNDJlNTYtM2M4MC00N2IxLWJiMDUtNTU5YzhmY2Y0Y2ViIn0.uyHeBPyus6K_RIEYmsmHEKaDPHoc0T4Du5k0pmldrTE",
      "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3ODI4NDUwMzIsImlhdCI6MTc4MjI0MDIzMiwic3ViIjoiNTJmNDJlNTYtM2M4MC00N2IxLWJiMDUtNTU5YzhmY2Y0Y2ViIn0.-VrZw7U4673Zb8DqW-5Hr5PGYvg_PoV1tDcichp50zs"
    },
    "user": {
      "id": "52f42e56-3c80-47b1-bb05-559c8fcf4ceb",
      "username": "abc.4130",
      "display_name": "abc.7118",
      "created_at": "2026-06-23T23:54:28.51477+05:30"
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
* **URL:** `/api/auth/refresh`
* **Method:** `POST`
* **Headers:** `Content-Type: application/json`
* **Authentication Required:** `NO`
* **curl:** `curl -X POST http://HOST:PORT/api/auth/refresh \ -H "Content-Type: application/json" \ -d '{
    "refresh_token": "{Refresh_token}"
  }' \ -s | jq .`

#### Request Body
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3ODI4NDUwMzIsImlhdCI6MTc4MjI0MDIzMiwic3ViIjoiNTJmNDJlNTYtM2M4MC00N2IxLWJiMDUtNTU5YzhmY2Y0Y2ViIn0.-VrZw7U4673Zb8DqW-5Hr5PGYvg_PoV1tDcichp50zs"
}
```

#### Expected Response

##### `200 OK` (Token Refresh Successful)
Returned when token is refreshed successfully
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3ODIyNDE1NzcsImlhdCI6MTc4MjI0MDY3Nywic3ViIjoiNTJmNDJlNTYtM2M4MC00N2IxLWJiMDUtNTU5YzhmY2Y0Y2ViIn0.lHWnl8WO107C1Q2DFyNS6_qWHlDDYJ5GH86SBVAz1AU",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3ODI4NDU0NzcsImlhdCI6MTc4MjI0MDY3Nywic3ViIjoiNTJmNDJlNTYtM2M4MC00N2IxLWJiMDUtNTU5YzhmY2Y0Y2ViIn0.APBzw1kRkWE7WRRJEWc4pkWz_k9BbQBTyDSw7CdRcw8"
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
* **URL:** `/api/users/me`
* **Method:** `GET`
* **Headers:** `Content-Type: application/json`
* **Authentication Required:** `YES`
* **curl:** `curl -X GET "http://HOST:PORT/api/users/me" \ -H "Authorization: Bearer <access_token>"`

#### Expected Responses

##### `200 OK`
Returned when user data is successfully retrevied
```json
{
  "success": true,
  "data": {
    "id": "bf4b6c67-1d2c-410b-b09e-151591d0d1b2",
    "username": "abc.1439",
    "display_name": "abc",
    "created_at": "2026-06-24T07:42:27.535937Z"
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
* **URL:** `/api/users/{id}`
* **Method:** `GET`
* **Headers:** `Content-Type: application/json`
* **Authentication Required:** `YES`
* **curl:** `curl -X GET "http://HOST:PORT/api/users/{id}" \ -H "Authorization: Bearer <access_token>"`

#### Expected Responses

##### `200 OK`
Returned when user is successfully found
```json
{
  "success": true,
  "data": {
    "id": "6e804cc7-e0dc-4448-854a-85deabe1bdac",
    "username": "abc.2605",
    "display_name": "abc",
    "created_at": "2026-06-24T07:42:52.550052Z"
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
Returned when access token is missing or expried or incorrect
```json
{
  "success": false,
  "error": "Access token missing, expired or malformed"
}
```

### 3. Search User by username and display name
Used to find user by username and display name
Get user data
* **URL:** `/api/users/search/?q={username}&page={page}&limit={limit}`
* **Method:** `GET`
* **Headers:** `Content-Type: application/json`
* **Authentication Required:** `YES`
* **curl:** `curl -X GET "http://HOST:PORT/api/users/search?q={name}&page={page}&limit={limit}" \ -H "Authorization: Bearer <access_token>"`

#### Expected Responses

##### `200 OK`
Returned when user is successfully found
```json
{
  "success": true,
  "data": [
    {
      "id": "bf4b6c67-1d2c-410b-b09e-151591d0d1b2",
      "username": "abc.1439",
      "display_name": "abc",
      "created_at": "2026-06-24T07:42:27.535937Z"
    },
    {
      "id": "ffe637cb-5e5c-4d22-8e47-1fcf1a164a9f",
      "username": "abc.1802",
      "display_name": "abc.7118",
      "created_at": "2026-06-23T18:27:44.753544Z"
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

* **URL:** `/api/ws?token=<access_token>`
* **Method:** `WS (websocket Upgrade)`
* **Headers:** `NONE`
* **Authentication Required:** `YES`
* **wscat:** `wscat -c "ws://HOST:PORT/api/ws?token={access_token}"`

### Expected Response

#### `101 Switching Protocols`
Returned when websocket is successfully connected
```
connected to ws://HOST:PORT/api/ws?token=<access_token>
```

#### `401 Unauthorized`
Returned when access token is expired or incorrect
```
WebSocket error: Unexpected server response: 404
```

## Messages Endpoints

### 1. Send Message

* **URL:** `/api/messages/`
* **Method:** `POST`
* **Headers:** `Content-Type: application/json`
* **Authentication Required:** `YES`
* **curl:** `curl -X POST "http://HOST:PORT/api/messages/" \ -H "Content-Type: application/json" \ -H "Authorization: Bearer <access_token>" \ -d '{
    "receiver_id": "{receiver_id}",
    "content": "{content}"
  }'`

#### Request Body
```json
{
  "receiver_id":"6e804cc7-e0dc-4448-854a-85deabe1bdac",
  "content":"YOO!"
}
```

#### Expected Response 

##### `201 Created`
Returned when message is successfully sent
```json
{
  "success": true,
  "data": {
    "id": "4c7b864e-4a08-4f85-a502-566199c620ca",
    "sender_id": "bf4b6c67-1d2c-410b-b09e-151591d0d1b2",
    "receiver_id": "6e804cc7-e0dc-4448-854a-85deabe1bdac",
    "content": "YOO!",
    "created_at": "2026-06-24T11:39:06.914325Z"
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
* **URL:** `/api/users/messages/?with={receiver_id}&before={ISO 8601}&limit={limit}`
* **Method:** `GET`
* **Headers:** `Content-Type: application/json`
* **Authentication Required:** `YES`
* **curl:** `curl -X GET "http://HOST:PORT/api/users/messages/?with={receiver_id}&before={time}&limit={limit}" \ -H "Authorization: Bearer <access_token>"`

#### Expected Response

##### `200 OK`
Returned when data is successfully retreived
```json
{
  "success": true,
  "data": [
    {
      "id": "7ffcc912-cb65-48c6-95d9-a2f1546ba1d3",
      "sender_id": "bf4b6c67-1d2c-410b-b09e-151591d0d1b2",
      "receiver_id": "6e804cc7-e0dc-4448-854a-85deabe1bdac",
      "content": "Hello!",
      "created_at": "2026-06-24T11:23:05.491839Z"
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