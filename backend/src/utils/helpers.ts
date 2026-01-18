import crypto from "crypto";

/**
 * Generate OTP token (6 digits)
 */
export function generateOTP(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Hash a value with SHA256
 */
export function hashSHA256(value: string): string {
  return crypto.createHash("sha256").update(value).digest("hex");
}

/**
 * Hash OTP for storage
 */
export function hashOTP(otp: string): string {
  return hashSHA256(otp + process.env.JWT_SECRET);
}

/**
 * Verify OTP
 */
export function verifyOTP(plainOTP: string, hashedOTP: string): boolean {
  return hashOTP(plainOTP) === hashedOTP;
}

/**
 * Format phone number to standard format (+233xxxxxxxxx)
 */
export function formatPhoneNumber(phone: string): string {
  // Remove all non-digits
  const digitsOnly = phone.replace(/\D/g, "");

  // Add country code if not present
  if (digitsOnly.startsWith("233")) {
    return "+" + digitsOnly;
  } else if (digitsOnly.startsWith("0")) {
    return "+233" + digitsOnly.substring(1);
  }

  throw new Error("Invalid phone number format");
}

/**
 * Validate GPS coordinates
 */
export function validateCoordinates(lat: number, lon: number): boolean {
  return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
}

/**
 * Validate ISO 8601 timestamp
 */
export function validateISO8601(dateString: string): boolean {
  const date = new Date(dateString);
  return !isNaN(date.getTime()) && dateString === date.toISOString();
}

/**
 * Calculate file checksum (SHA256)
 */
export async function calculateFileChecksum(buffer: Buffer): Promise<string> {
  return hashSHA256(buffer.toString("base64"));
}

/**
 * Generate secure random token
 */
export function generateSecureToken(length: number = 32): string {
  return crypto.randomBytes(length).toString("hex");
}

/**
 * Calculate points for report verification
 * Current: 10 points per verified report
 */
export function calculateReportPoints(): number {
  return 10;
}
