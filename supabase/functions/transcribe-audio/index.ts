/// <reference lib="deno.ns" />
// @ts-nocheck
// Import dependencies
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// CORS headers for Flutter app
const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function assertStorageObjectPath(value: unknown): string {
  if (typeof value !== 'string') {
	throw new Error('audioUrl must be a string storage object path');
  }

  const v = value.trim();
  if (!v) {
	throw new Error('audioUrl is required');
  }

  // We expect a bucket-relative storage object path (e.g. "lectures/abc.mp3"),
  // not a full URL. This keeps download() correct and avoids leaking public URLs.
  if (/^https?:\/\//i.test(v) || v.startsWith('gs://')) {
	throw new Error(
	  'audioUrl must be a Supabase Storage object path (e.g. "lectures/abc.mp3"), not a full URL',
	);
  }

  // Basic path hardening: reject traversal and backslashes.
  if (v.includes('..') || v.includes('\\')) {
	throw new Error('Invalid audioUrl path');
  }

  return v;
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
	return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
	return new Response(JSON.stringify({ success: false, error: 'Method not allowed' }), {
	  status: 405,
	  headers: { ...corsHeaders, 'Content-Type': 'application/json' },
	});
  }

  try {
	// Get request data
	const body = await req.json();
	const audioUrl = assertStorageObjectPath(body.audioUrl);
	const lectureId = body.lectureId;

	if (!lectureId) {
	  throw new Error('lectureId is required');
	}

	console.log(`Processing lecture: ${lectureId}, audio: ${audioUrl}`);

	// Initialize Supabase
	const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
	const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
	const supabase = createClient(supabaseUrl, supabaseKey);

	// Get Gemini API key
	const geminiApiKey = Deno.env.get('GEMINI_API_KEY');

	if (!geminiApiKey) {
	  throw new Error('GEMINI_API_KEY not configured');
	}

	// 1. Download audio from Supabase Storage
	console.log('Downloading audio file...');
	const { data: audioData, error: downloadError } = await supabase
	  .storage
	  .from('lecture-audio')
	  .download(audioUrl);

	if (downloadError) {
	  throw new Error(`Download failed: ${downloadError.message}`);
	}

	// 2. Convert to base64
	console.log('Converting to base64...');
	const arrayBuffer = await audioData.arrayBuffer();
	const bytes = new Uint8Array(arrayBuffer);
	const base64Audio = btoa(String.fromCharCode(...bytes));

	// 3. Call Gemini API
	console.log('Calling Gemini API...');
	const geminiResponse = await fetch(
	  `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${geminiApiKey}`,
	  {
		method: 'POST',
		headers: {
		  'Content-Type': 'application/json',
		},
		body: JSON.stringify({
		  contents: [{
			parts: [
			  {
				inline_data: {
				  mime_type: 'audio/mp3',
				  data: base64Audio,
				},
			  },
			  {
				text: `Please process this lecture audio and output ONLY valid JSON in the exact schema below.

{
  "title": "Introduction to Data Structures",
  "summary": "Brief overview...",
  "key_points": ["Point 1", "Point 2"],
  "assignments_and_assessments": {
    "assignments": [{
      "description": "Complete binary tree problems",
      "deadline": "Next Friday",
      "requirements": ["Problem 1-5", "Include analysis"]
    }],
    "cas": [{
      "description": "Quiz on arrays",
      "date": "March 25"
    }]
  },
  "action_items_for_students": [
    "Review chapter 3",
    "Practice sorting algorithms"
  ],
  "previous_topics_mentioned": [
    "We covered arrays last week..."
  ],
  "full_transcript": "Complete verbatim transcript..."
}

Rules:
- Return ONLY JSON (no markdown, no backticks, no extra text).
- Keep arrays as arrays.
- If a field is unknown, use an empty string/array/object but keep the key.
`,
			  },
			],
		  }],
		  generationConfig: {
			temperature: 0.4,
			topK: 32,
			topP: 1,
			maxOutputTokens: 8192,
		  },
		}),
	  },
	);

	if (!geminiResponse.ok) {
	  const errorText = await geminiResponse.text();
	  throw new Error(`Gemini API error: ${errorText}`);
	}

	const geminiData = await geminiResponse.json();

	// 4. Parse response
	const responseText = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
	if (typeof responseText !== 'string' || responseText.trim().length === 0) {
	  throw new Error('Gemini response was empty');
	}

	let result: {
	  title: string;
	  summary: string;
	  key_points: string[];
	  assignments_and_assessments: {
		assignments: Array<{
		  description: string;
		  deadline: string;
		  requirements: string[];
		}>;
		cas: Array<{
		  description: string;
		  date: string;
		}>;
	  };
	  action_items_for_students: string[];
	  previous_topics_mentioned: string[];
	  full_transcript: string;
	};

	try {
	  const jsonMatch = responseText.match(/\{[\s\S]*\}/);
	  if (jsonMatch) {
		result = JSON.parse(jsonMatch[0]);
	  } else {
		result = JSON.parse(responseText);
	  }
	} catch (_parseError) {
	  console.error('Parse error:', responseText);
	  throw new Error('Failed to parse Gemini response');
	}

	// 5. Save to database
	// Table/columns updated to match current schema:
	// - table: lectures
	// - transcript column: transcription (we map from full_transcript)
	// - status: completed/failed
	// - transcription_result: JSONB (stores the entire structured result)
	console.log('Saving to database...');
	const { error: updateError } = await supabase
	  .from('lectures')
	  .update({
		transcription: result.full_transcript,
		summary: result.summary,
		// Store the entire structured JSON in a single JSONB column to avoid
		// schema mismatch failures when adding new fields.
		transcription_result: result,
		status: 'completed',
		processed_at: new Date().toISOString(),
	  })
	  .eq('id', lectureId);

	if (updateError) {
	  // Best effort: mark as failed so the UI can show useful feedback.
	  await supabase
		.from('lectures')
		.update({
		  status: 'failed',
		  error_message: updateError.message,
		})
		.eq('id', lectureId);

	  throw new Error(`Database update failed: ${updateError.message}`);
	}

	console.log('Success!');

	return new Response(
	  JSON.stringify({
		success: true,
		message: 'Audio transcribed successfully',
		data: {
		  transcription: result.full_transcript,
		  summary: result.summary,
		  transcription_result: result,
		},
	  }),
	  {
		headers: { ...corsHeaders, 'Content-Type': 'application/json' },
		status: 200,
	  },
	);
  } catch (error) {
	console.error('Error:', error);

	return new Response(
	  JSON.stringify({
		success: false,
		error: (error as Error)?.message ?? 'Bad request',
	  }),
	  {
		headers: { ...corsHeaders, 'Content-Type': 'application/json' },
		status: 400,
	  },
	);
  }
});
