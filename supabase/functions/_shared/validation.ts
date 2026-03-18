const ICTU_DOMAIN = '@ictuniversity.edu.cm';

export function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

export function assertIctuEmail(email: string): void {
  const normalized = normalizeEmail(email);
  if (!normalized.endsWith(ICTU_DOMAIN)) {
    throw new Error(`Email must end with ${ICTU_DOMAIN}`);
  }
}

export function assertStrongPassword(password: string): void {
  if (typeof password !== 'string' || password.length < 8) {
    throw new Error('Password must be at least 8 characters');
  }
}

// IMPORTANT: since students can choose role/faculty, we enforce allowlists.
// Update these arrays to match your real options.
export const ALLOWED_ROLES = ['student', 'delegate', 'lecturer'] as const;
export type AllowedRole = (typeof ALLOWED_ROLES)[number];

// Keep this permissive for now; tighten to a fixed list when you know values.
export function assertFaculty(faculty: string): void {
  if (typeof faculty !== 'string' || faculty.trim().length < 2) {
    throw new Error('Faculty is required');
  }
}

export function assertRole(role: string): asserts role is AllowedRole {
  if (!ALLOWED_ROLES.includes(role as AllowedRole)) {
    throw new Error(`Invalid role. Allowed roles: ${ALLOWED_ROLES.join(', ')}`);
  }
}

