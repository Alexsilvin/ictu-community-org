-- Add a JSONB column to store the full structured transcription result
-- Generated: 2026-03-21
--
-- Notes:
-- - This column is used by the Edge Function: supabase/functions/transcribe-audio/index.ts
-- - JSONB allows flexible schema evolution without adding many columns.

alter table public.lectures
add column if not exists transcription_result jsonb;

-- Optional: helpful index for querying inside the JSON (uncomment if needed)
-- create index if not exists lectures_transcription_result_gin_idx
-- on public.lectures
-- using gin (transcription_result);

