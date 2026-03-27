# API Documentation

This folder documents the project's APIs (Supabase Edge Functions) and keeps a running log of test attempts.

## Endpoints

- [Auth: Register](./endpoints/auth_register.md)
- [Auth: Login](./endpoints/auth_login.md)

## Test logs

- [Auth test log](./testing/auth_test_log.md)

## Code locations (quick links)

### Backend (Supabase Edge Functions)

- `register`: `supabase/functions/register/index.ts`
- `login`: `supabase/functions/login/index.ts`

### Flutter client (where endpoints are called)

- Invoked via: `lib/features/auth/data/auth_api.dart`
  - `AuthApi.register()` → invokes function name `register`
  - `AuthApi.login()` → invokes function name `login`

### Notes

- The public URLs are:
  - `POST https://<project-ref>.supabase.co/functions/v1/register`
  - `POST https://<project-ref>.supabase.co/functions/v1/login`

- Do **not** store the service role key in the Flutter app.

