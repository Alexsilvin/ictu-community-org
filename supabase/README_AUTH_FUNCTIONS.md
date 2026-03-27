# Supabase Edge Functions (Auth)

This repo contains two Supabase Edge Functions:

- `register` -> `supabase/functions/register/index.ts`
- `login` -> `supabase/functions/login/index.ts`

They are called from the public URLs:

- `POST https://<project-ref>.supabase.co/functions/v1/register`
- `POST https://<project-ref>.supabase.co/functions/v1/login`

## API documentation & test logs (source of truth)

See `docs/api/` for:

- Endpoint documentation: `docs/api/endpoints/`
- Successful/unsuccessful test records: `docs/api/testing/auth_test_log.md`

## Required function secrets

Set these secrets in Supabase (Dashboard > Edge Functions > Secrets) or via CLI:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

⚠️ Never put the service role key in the Flutter app.

## Deploying

### Option 1: Supabase Dashboard (no CLI)

1. Go to Supabase Dashboard -> Edge Functions -> Create a new function.
2. Create **two** functions named exactly: `register` and `login`.
3. Paste the contents from the corresponding `index.ts` files in this repo.
4. Add the secrets above.
5. Deploy.

### Option 2: Supabase CLI

Install the CLI and login:

```bat
scoop install supabase
supabase login
```

Then from the repo root:

```bat
cd /d S:\ictu-community-org
supabase functions deploy register
supabase functions deploy login
```

Add secrets (one-time):

```bat
supabase secrets set SUPABASE_URL=https://<project-ref>.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

## Postman test

### Register

```http
POST https://<project-ref>.supabase.co/functions/v1/register
Content-Type: application/json

{
  "email": "someone@ictuniversity.edu.cm",
  "password": "mypassword123",
  "username": "John Doe",
  "role": "student",
  "faculty": "FET"
}
```

### Login

```http
POST https://<project-ref>.supabase.co/functions/v1/login
Content-Type: application/json

{
  "email": "someone@ictuniversity.edu.cm",
  "password": "mypassword123"
}
```

