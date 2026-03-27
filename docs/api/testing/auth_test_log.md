# Auth API Test Log

Use this document to record *every* manual/automated test attempt for the auth endpoints.

> Redact secrets/tokens. Do not paste full JWTs or service role keys.

## How to add a new entry

Copy the template section below and fill it in.

---

## Entry template

**Date:** YYYY-MM-DD

**Tester:** <name>

**Environment:** local | staging | prod

**Project ref:** <supabase-project-ref>

**Endpoint:** register | login

**Method:** POST

**Request**

- Headers:
  - Content-Type: application/json
- Body:

```json
{
}
```

**Expected result:**

**Actual result:**

- HTTP status: <code>
- Response body:

```json
{
}
```

**Outcome:** ✅ Success | ❌ Failed

**Notes / follow-ups:**

---

## Recorded tests

### 2026-03-21

#### Login — example failed test (domain validation)

**Date:** 2026-03-21

**Tester:** (fill)

**Environment:** (fill)

**Project ref:** (fill)

**Endpoint:** login

**Request**

```json
{
  "email": "someone@ictuniversity.edu.cm",
  "password": "password123"
}
```

**Outcome:** (fill)

**Notes:** If Flutter shows a different domain error than backend, check client validator: `lib/features/auth/utils/auth_validation.dart`.

