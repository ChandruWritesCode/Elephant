# Elephant Messenger API Contracts

## Global Requirements & Configuration

- **Base URL:** `http://HOST:PORT` (Local Sandbox)
- **Default Content-Type:** `application/json`
- **Authorization:** `Bearer <access_token>`
- **Timestamp Format:** `ISO8601 UTC`
---

## API Overview

| Method | Endpoint | Description |
|---|---|---|
| GET | [/api/health](#health-endpoint)| Health check (server + database status) |
| POST | [/api/auth/register](#1-register-user) | Register a new user |
| POST | [/api/auth/login](#2-login-user) | Log in and receive a token pair |
| POST | [/api/auth/refresh](#3-refresh) | Exchange a refresh token for a new token pair |
| GET | [/api/users/me](#1-user-me) | Get the authenticated user's profile |
| GET | [/api/users/:id](#2-search-user-by-id) | Search users by username or display name |
| GET | [/api/users/search?q=&page=&limit=](#3-search-user-by-username-and-display-name) | Get a public user profile |
| GET | [/ws](#1-connect-to-websocket) | WebSocket upgrade endpoint (JWT required) |
| WS | [Client to Server](#2-client-to-server-messages) | Client to Server Websocket |
| WS | [Server to Client](#3-server-to-client-messages) | Server to Client Websocket |
| POST | [/api/messages](#1-send-message) | Send a message (REST fallback) |
| GET | [/api/messages?with=&before=&limit=](#2-message-history) | Paginated message history |
| GET | [/api/messages/conversations](#3-conversations) | Get user conversatiosn |
| POST | [/api/messages/read](#4-read) | Get read mark |
| POST | [/api/groups/](#1-create-group) | Create Group |
| GET | [/api/groups/](#2-get-groups) | Get all groups of user |
| GET | [/api/group/{id}](#3-get-group-by-group-id) | Get group by group id |
| GET | [/api/groups/{id}/messages](#4-get-messages-of-group) | Get message of a group |
| GET | [/api/groups/{id}/members](#5-group-members) | Get group members |
| POST | [/api/groups/{id}/leave](#6-leave-group) | Leave a group |
| PATCH | [/api/groups/{id}/](#7-update-group-details) | Update Group Details |
| POST | [/api/groups/{id}/members](#8-add-member-to-group) | Add members to group |
| DELETE | [/api/groups/{id}/members/{user_id}](#9-remove-user-from-group) | Remove member from group |


## Health Endpoint

Evaluates the operational status of the server application and its upstream resource dependencies (such as the PostgreSQL database pool).

- **URL:** `/api/health`
- **Method:** `GET`
- **Authentication Required:** `NO`
- **curl:** `curl -X GET http://HOST:PORT/api/health -s | jq .`

### Expected Responses

#### `200 OK` (System operational)

Returned when the server runtime is healthy and can successfully execute a ping query against the database.

```json
{
  "success": true,
  "data": {
    "postgres": "up",
    "timestamp": "<TimeStamp>"
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
    "timestamp": "<TimeStamp>"
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
- **curl:** `curl -X POST http://HOST:PORT/api/auth/register  -H "Content-Type: application/json" -d '{ "username": "<username>", "display_name": "Full Name", "password": "<password>" }' -s`

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
      "created_at": "<TimeStamp>"
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
- **curl:** `curl -X POST http://HOST:PORT/api/auth/login -H "Content-Type: application/json" -d '{ "username": "<username>", "password": "<password>" }' -s`

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
      "created_at": "<Timestamp>"
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
- **curl:** `curl -X POST http://HOST:PORT/api/auth/refresh -H "Content-Type: application/json" -d '{ "refresh_token": "<refresh_token>" }' -s`

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
- **curl:** `curl -X GET "http://HOST:PORT/api/users/me" -H "Authorization: Bearer <access_token>"`

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
    "created_at": "<Timestamp>"
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
- **curl:** `curl -X GET "http://HOST:PORT/api/users/{id}" -H "Authorization: Bearer <access_token>"`

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
    "created_at": "<Timestamp>"
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
- **curl:** `curl -X GET "http://HOST:PORT/api/users/search?q={name}&page={page}&limit={limit}" -H "Authorization: Bearer <access_token>"`

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
      "created_at": "<Timestamp>"
    },
    {
      "id": "bbbbbbbb-bbbb-bbbb-bbbbbbbbbbbb",
      "username": "<username>",
      "display_name": "Full Name",
      "created_at": "<Timestamp>"
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

### 1. Connect to websocket

- **URL:** `/api/ws?token={access_token}`
- **Method:** `WS (websocket Upgrade)`
- **Headers:** `NONE`
- **Authentication Required:** `YES`
- **wscat:** `wscat -c "ws://HOST:PORT/api/ws?token={access_token}"`

#### Expected Response

##### `101 Switching Protocols`

Returned when websocket is successfully connected

```
connected to ws://HOST:PORT/api/ws?token={access_token}
```

##### `Unexpected server response: 404`

Returned when access token is expired or incorrect

```
WebSocket error: Unexpected server response: 404
```

### Notes
* If chat is done in group group_id will be used instead of receiver_id and vice versa.

### 2. Client to Server Messages

#### 1. Send Chat Message
Sends a direct or group message. 

##### Request Body
No Reply
```json
{
  "type":"chat",
  "receiver_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "content":"<content>"
}
```
Reply
```json
{
  "type":"chat",
  "receiver_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "content":"<content>",
  "reply_to_message_id":"<message_id of message being replied to>"
}
```
##### Notes
* If chat is done in group group_id will be used instead of receiver_id and vice versa.


#### 2. Read Recipet
Marks messages as read.

##### Request Body
```json
{
  "type":"read_receipt",
  "receiver_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
}
```
##### Notes
* If chat is done in group group_id will be used instead of receiver_id and vice versa.

#### 3. Request Online Status
Checks whether a specific user is currently connected.

##### Request Body
```json
{
  "type":"request_status",
  "receiver_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
}
```
##### Notes
* If chat is done in group group_id will be used instead of receiver_id and vice versa.

#### 4. Typing Indicator


##### Request Body
```json
{
  "type": "typing",
  "receiver_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
}
```
##### Notes
* If chat is done in group group_id will be used instead of receiver_id and vice versa.

### 3. Server to Client Messages

#### 1. Incoming Chat Message (no reply)
Delivered when another user sends you a direct or group message.

##### Response
```json
{
  "type": "chat",
  "sender_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "receiver_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  "content": "<content>",
  "message_id": "<message_id>",
  "timestamp": "<Timestamp>"
}
```
##### Notes
* If chat is done in group group_id will be used instead of receiver_id and vice versa.

#### 2. Incoming Chat Message (with reply)
Delivered when another user replies to a message. Includes the original quoted message.

##### Response
```json
{
  "type": "chat",
  "sender_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "receiver_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  "content": "<content>",
  "message_id": "<message_id>",
  "reply_to_message_id": "<message_id_of_message_to_be_replied>",
  "timestamp": "<created_time>",
  "quoted_message": {
    "content": "<original message content>",
    "sender_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
  }
}
```
##### Notes
* If chat is done in group group_id will be used instead of receiver_id and vice versa.

#### 3. Typing Indicator
Delivered when another user is typing to you or in a shared group.

##### Response
```json
{
  "type": "typing",
  "sender_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "receiver_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
}
```
##### Notes
* If chat is done in group group_id will be used instead of receiver_id and vice versa.

#### 4. Read Receipt
Delivered when the recipient reads your message.

##### Response
```json
{
  "type": "read_receipt",
  "sender_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "receiver_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  "timestamp": "<created_time>"
}
```
##### Notes
* If chat is done in group group_id will be used instead of receiver_id and vice versa.

#### 5. User Status
Broadcast to all connected clients when a user connects or disconnects. Also sent as a direct response to request_status

##### Response
```json
{
  "type": "user_status",
  "user_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "online": true
}
```
##### Notes
* If chat is done in group group_id will be used instead of receiver_id and vice versa.

## Messages Endpoints

### 1. Send Message

- **URL:** `/api/messages/`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X POST "http://HOST:PORT/api/messages/" -H "Content-Type: application/json" -H "Authorization: Bearer <access_token>" -d '{ "receiver_id": "<receiver_id>", "content": "<content>" }'`

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

- **URL:** `/api/messages/?with={receiver_id}&before={time}&limit={limit}`
- **Method:** `GET`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X GET "http://HOST:PORT/api/messages/?with={receiver_id}&before={time}&limit={limit}" -H "Authorization: Bearer <access_token>"`

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
      "created_at": "<Timestamp>"
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

### 3. Conversations
To retrieve user conversations

- **URL:** `/api/messages/conversations`
- **Method:** `GET`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X GET "http://HOST:PORT/api/messages/conversations" -H "Authorization: Bearer <access_token>"`

#### Expected Response

##### `200 OK`
Conversations is successfully retrieved.
```json
{
  "success": true,
  "data": [
    {
      "id": "<user_id of receiver>",
      "type": "<direct or group>",
      "name": "<username>",
      "display_name": "<display Name>",
      "last_message": "<content>",
      "last_message_time": "<last message time>",
      "sender_id": "<user_id>",
      "is_read": (bool)"<read of coresponding user>",
      "unread_count": (int)0"<unread_count of corresponding user>"
    }
  ]
}
```

##### `401 Unauthorized`
Access token is missing or expired.
```json
{
  "success": false,
  "error": "Access token missing, expired or malformed"
}
```

### 4. Read
To get read mark for a user

- **URL:** `/api/messages/read`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X POST "http://HOST:PORT/api/messages/read" -H "Authorization: Bearer <access_token>" -d '{ "sender_id": "<sender_id>" }'`

#### Request Body
```json
{
  "sender_id":"<sender_id>"
}
```

#### Expected Responses

##### `200 OK`
```json
{
  "success": true,
  "data": "Target messages marked read successfully"
}
```

##### `401 Unauthorized`
```json
{
  "success": false,
  "error": "Access token missing, expired or malformed"
}
```

## Group Endpoints

### 1. Create Group
- **URL:** `/api/groups/`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X POST "http://HOST:PORT/api/groups/" -H "Authorization: Bearer <access_token>" -d '{ "name" : "group_name" }'`

#### Request Body
```json
{
  "name":"<group_name>"
}
```

#### Expected Responses

##### `201 Created`
Returned when group is successfully created
```json
{
  "success": true,
  "data": {
    "id": "<group_id>",
    "name": "noobs",
    "created_by": "<creator_id>",
    "created_at": "<Timestamp>"
  }
}
```

##### `401 Unauthorized`
Returned when access token is expried or incorrect.
```json
{
  "success": false,
  "error": "Access token missing, expired or malformed"
}
```

### 2. Get Groups

- **URL:** `/api/groups/`
- **Method:** `GET`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X GET "http://HOST:PORT/api/groups/" -H "Authorization: Bearer <access_token>"`

#### Expected Response

##### `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "id": "<group_id>",
      "name": "<group_name>",
      "created_by": "<creator_id>",
      "created_at": "<Timestamp>"
    },
    {
      "id": "<group_id>",
      "name": "<group_name>",
      "created_by": "<creator_id>",
      "created_at": "<Timestamp>"
    }
  ]
}
```

##### `401 Unauthorized`
```json
{
  "success": false,
  "error": "Access token missing, expired or malformed"
}
```

### 3. Get Group by Group ID

- **URL:** `/api/groups/{id}`
- **Method:** `GET`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X GET "http://HOST:PORT/api/groups/{id}" -H "Authorization: Bearer <access_token>"`

#### Expected Response

##### `200 OK`
Returned when group with given id is retrieved

```json
{
  "success": true,
  "data": [
    {
      "id": "<group_id>",
      "name": "<group_name>",
      "created_by": "<creator_id>",
      "created_at": "Timestamp"
    },
    {
      "id": "<group_id>",
      "name": "<group_name>",
      "created_by": "<creator_id>",
      "created_at": "Timestamp"
    }
  ]
}
```

##### `403 Forbidden`
Returned when you are not a member of group with given group id or the group id is incorrect

```json
{
  "success": false,
  "error": "Access denied: you are not a member of this group"
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

### 4. Get messages of group

- **URL:** `/api/groups/{id}/messages`
- **Method:** `GET`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X GET "http://HOST:PORT/api/groups/{id}/messages" -H "Authorization: Bearer <access_token>"`

#### Expected Response

##### `200 OK`
Returned when messages is successfully retrieved
```json
{
  "success": true,
  "data": [
    {
      "id": "<message_id>",
      "sender_id": "<sender_id>",
      "group_id": "<group_id>",
      "content": "<content>",
      "created_at": "<Timestamp>",
      "is_read": (bool)"<read_status>"
    }
  ]
}
```

##### `403 Forbidden`
Returned if user are not member of the group with given group id or group id is incorrect
```json
{
  "success": false,
  "error": "Access denied: you are not a member of this group"
}
```

##### `401 Unauthorized`
Returned if access token is expired or incorrect
```json
{
  "success": false,
  "error": "Access token missing, expired or malformed"
}
```

### 5. Group members
Get members of a group

- **URL:** `/api/groups/{id}/members`
- **Method:** `GET`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X GET "http://HOST:PORT/api/groups/{id}/members" -H "Authorization: Bearer <access_token>"`

#### Expected Response

##### `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "user_id": "<user_id>",
      "username": "<username>",
      "display_name": "<Full Name>",
      "role": "<role>",
      "joined_at": "Timestamp"
    },
    {
      "user_id": "<user_id>",
      "username": "<username>",
      "display_name": "<Full Name>",
      "role": "<role>",
      "joined_at": "Timestamp"
    }
  ]
}
```
* **Note:** Role can either be admin or member. 

##### `403 Forbidden`
Returned when user is not a member of group with given group id or group id is incorrect or if user is not admin of group
```json
{
  "success": false,
  "error": "Access denied: you are not a member of this group"
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


### 6. Leave Group

- **URL:** `/api/messages/groups/{id}/leave`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **curl:** `curl -X POST "http://HOST:PORT/api/groups/{id}/leave" -H "Authorization: Bearer <access_token>"`

#### Expected Response

##### `200 OK`
Returned when user successfully left the group
```json
{
  "success": true,
  "data": "You have left the group"
}
```

##### `403 Forbidden`
Returned when user is not a member of group with given group id or group id is incorrect or if user is not admin of group
```json
{
  "success": false,
  "error": "Access denied: you are not a member of this group"
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

### 7. Update Group Details

- **URL:** `/api/messages/groups/{id}/`
- **Method:** `PATCH`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **Admin Access Required:** `YES`
- **curl:** `curl -X PATCH "http://HOST:PORT/api/groups/{id}/" -H "Authorization: Bearer <access_token>" -d '{ "name":"<group_name>" }'`

#### Response Body
```json
{
  "name":"<new_group_name>"
}
```

#### Expected Response

##### `200 OK`
Returned when group details are successfully updated.
```json
{
  "success": true,
  "data": "Group details updated successfully"
}
```

##### `403 Forbidden`
Returned when user is not a member of group with given group id or group id is incorrect or if user is not admin of group
```json
{
  "success": false,
  "error": "Access denied: you are not a member of this group"
}
```
```json
{
  "success": false,
  "error": "Administrative clearance privileges required"
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

### 8. Add Member to group
- **URL:** `/api/messages/groups/{id}/members`
- **Method:** `POST`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **Admin Access Required:** `YES`
- **curl:** `curl -X POST "http://HOST:PORT/api/groups/{id}/members" -H "Authorization: Bearer <access_token>" -d '{ "user_id":"<user_id>" }'`

#### Request Body
```json
{
  "user_id":"<user_id>"
}
```

#### Expected Responses

##### `200 OK`
Returned when user is successfully added to group
```json
{
  "success": true,
  "data": "User attached to channel context cleanly"
}
```

##### `500 Internal Server Error`
Returned when user with given user id does not exist
```json
{
  "success": false,
  "error": "Failed to add member to channel"
}
```

##### `403 Forbidden`
Returned when user is not a member of group with given group id or group id is incorrect or if user is not admin of group
```json
{
  "success": false,
  "error": "Access denied: you are not a member of this group"
}
```
```json
{
  "success": false,
  "error": "Administrative clearance privileges required"
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

### 9. Remove User from Group
- **URL:** `/api/messages/groups/{id}/members/{user_id}`
- **Method:** `DELETE`
- **Headers:** `Content-Type: application/json`
- **Authentication Required:** `YES`
- **Admin Access Required:** `YES`
- **curl:** `curl -X DELETE "http://HOST:PORT/api/groups/{id}/members/{user_id}" -H "Authorization: Bearer <access_token>"`

#### Expected Response

##### `200 OK`
Returned when user is successfully removed from group
```json
{
  "success": true,
  "data": "Member detached from group context cleanly"
}
```
##### `500 Internal Server Error`
Returned when user with given user id does not exist
```json
{
  "success": false,
  "error": "Failed to add member to channel"
}
```

##### `403 Forbidden`
Returned when user is not a member of group with given group id or group id is incorrect or if user is not admin of group
```json
{
  "success": false,
  "error": "Access denied: you are not a member of this group"
}
```
```json
{
  "success": false,
  "error": "Administrative clearance privileges required"
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