# Auth API — Login (`POST /functions/v1/login`)

## Purpose
Signs a user in using email/password and returns a session JWT plus profile.

## Backend implementation (source of truth)

- File: `supabase/functions/login/index.ts`
- Key constants / validation:
  - `ICTU_DOMAIN = '@ictuniversity.edu.cm'`

## Flutter client integration

- Function invoked from Flutter:
  - File: `lib/features/auth/data/auth_api.dart`
  - Method: `AuthApi.login(...)`
  - Implementation: `SupabaseClient.functions.invoke('login', body: {...})`

## Request

### URL

`POST https://<project-ref>.supabase.co/functions/v1/login`

### Headers

- `Content-Type: application/json`

### JSON body

```json
{
  "email": "someone@ictuniversity.edu.cm",
  "password": "mypassword123"
}
```

### Notes on validation (backend)

- `email` must end with `@ictuniversity.edu.cm`
- `password` must be at least 8 characters

## Success response (200)

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

- `400` — validation failed in the function wrapper (missing fields or bad email/password)
- `401` — wrong email/password (Supabase auth returns unauthorized)
- `405` — method not allowed (non-POST)
- `500` — missing secrets (`SUPABASE_URL` or `SUPABASE_SERVICE_ROLE_KEY`)

## Test logging

Record successful/unsuccessful tests here:

- `docs/api/testing/auth_test_log.md`

