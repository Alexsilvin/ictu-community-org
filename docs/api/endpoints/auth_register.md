# Auth API — Register (`POST /functions/v1/register`)

## Purpose
Creates a new Supabase auth user, stores a profile row, then signs the user in and returns a session JWT.

## Backend implementation (source of truth)

- File: `supabase/functions/register/index.ts`
- Key constants / validation:
  - `ICTU_DOMAIN = '@ictuniversity.edu.cm'`
  - Allowed roles: `student | delegate | lecturer`

## Flutter client integration

- Function invoked from Flutter:
  - File: `lib/features/auth/data/auth_api.dart`
  - Method: `AuthApi.register(...)`
  - Implementation: `SupabaseClient.functions.invoke('register', body: {...})`

## Request

### URL

`POST https://<project-ref>.supabase.co/functions/v1/register`

### Headers

- `Content-Type: application/json`

### JSON body

```json
{
  "email": "someone@ictuniversity.edu.cm",
  "password": "mypassword123",
  "username": "John Doe",
  "role": "student",
  "faculty": "FET"
}
```

### Notes on validation (backend)

- `email` must end with `@ictuniversity.edu.cm`
- `password` must be at least 8 characters
- `role` must be one of: `student`, `delegate`, `lecturer`
- `faculty` must be at least 2 characters

## Success response (200)

Shape returned (see `return jsonResponse(200, {...})`):

```json
{
  "access_token": "<jwt>",
  "refresh_token": "<jwt>",
  "expires_in": 3600,
  "token_type": "bearer",
  "user": {
    "id": "...",
    "email": "...",
    "profile": {
      "id": "...",
      "full_name": "...",
      "email": "...",
      "role": "student",
      "faculty": "FET",
      "created_at": "..."
    }
  }
}
```

## Error responses

The function returns JSON like:

```json
{ "error": "<message>" }
```

Common statuses:

- `400` — validation failed, user creation failed, profile write failed, or sign-in-after-registration failed
- `405` — method not allowed (non-POST)
- `500` — missing secrets (`SUPABASE_URL` or `SUPABASE_SERVICE_ROLE_KEY`)

## Test logging

Record successful/unsuccessful tests here:

- `docs/api/testing/auth_test_log.md`

