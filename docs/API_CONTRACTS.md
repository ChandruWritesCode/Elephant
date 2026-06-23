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
* **curl:** `curl -X GET http://localhost:8080/api/health \ -H "Content-Type: application/json" \ -s | jq .`

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
* **curl:** `curl -X POST http://localhost:8080/api/auth/register \ -H "Content-Type: application/json" \ -d '{
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
* **curl:** `curl -X POST http://localhost:8080/api/auth/login \ -H "Content-Type: application/json" \ -d '{
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
* **curl:** `curl -X POST http://localhost:8080/api/auth/refresh \ -H "Content-Type: application/json" \ -d '{
    "refresh_token": "YOUR_REFRESH_TOKEN_HERE"
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
Used to search for users
* **URL:** `/api/users/search`
* **Used As:** `/api/users/search?q={username}`
* **Method:** `GET`
* **Headers:** `Content-Type: application/json`
* **Authentication Required:** `NO`
* **curl:** `curl -X GET "http://localhost:8080/api/users/search?q=abc" \ -H "Content-Type: application/json" \ -s | jq .`

### Expected Response

### `200 OK`
Returned when search is successful
```json
{
  "success": true,
  "data": [
    {
      "id": "ffe637cb-5e5c-4d22-8e47-1fcf1a164a9f",
      "username": "abc.1802",
      "display_name": "abc.7118",
      "created_at": "2026-06-23T23:57:44.753544+05:30"
    }
  ]
}
```

If no matching user found.
```json
{
  "success": true,
  "data": []
}
```