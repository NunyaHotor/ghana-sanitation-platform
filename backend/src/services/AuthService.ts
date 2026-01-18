import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";
import { AppDataSource } from "../database";
import { User, UserRole } from "../entities/User";
import { AppError, ValidationError, AuthenticationError, ConflictError } from "../utils/errors";
import { generateOTP, hashOTP, verifyOTP, formatPhoneNumber, generateSecureToken } from "../utils/helpers";

export interface JWTPayload {
  userId: string;
  phone_number: string;
  role: UserRole;
}

export interface AuthTokens {
  access_token: string;
  refresh_token: string;
  user_id: string;
  expires_in: number;
}

const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key";
const JWT_EXPIRY = process.env.JWT_EXPIRY || "7d";
const JWT_REFRESH_EXPIRY = process.env.JWT_REFRESH_EXPIRY || "30d";
const OTP_EXPIRY_MINUTES = parseInt(process.env.OTP_EXPIRY_MINUTES || "5");

export class AuthService {
  private userRepository = AppDataSource.getRepository(User);

  /**
   * Request OTP via SMS for phone number
   */
  async requestOTP(phoneNumber: string): Promise<{ otp_expires_in: number }> {
    try {
      const formattedPhone = formatPhoneNumber(phoneNumber);

      // Check if user exists or create
      let user = await this.userRepository.findOne({
        where: { phone_number: formattedPhone },
      });

      if (!user) {
        user = this.userRepository.create({
          phone_number: formattedPhone,
          role: UserRole.CITIZEN,
        });
      }

      // Generate OTP
      const otp = generateOTP();
      const hashedOTP = hashOTP(otp);
      const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

      user.otp_token = hashedOTP;
      user.otp_expires_at = expiresAt;
      user.otp_verified = false;

      await this.userRepository.save(user);

      // TODO: Send OTP via SMS (Twilio/Nexmo integration)
      console.log(`[DEV] OTP for ${formattedPhone}: ${otp}`);

      return {
        otp_expires_in: OTP_EXPIRY_MINUTES * 60, // seconds
      };
    } catch (error) {
      if (error instanceof ValidationError) {
        throw error;
      }
      throw new AppError("Failed to request OTP", 500);
    }
  }

  /**
   * Verify OTP and return JWT tokens
   */
  async verifyOTP(phoneNumber: string, otpCode: string): Promise<AuthTokens> {
    try {
      const formattedPhone = formatPhoneNumber(phoneNumber);

      const user = await this.userRepository.findOne({
        where: { phone_number: formattedPhone },
      });

      if (!user) {
        throw new AuthenticationError("User not found");
      }

      // Check OTP validity
      if (!user.otp_token) {
        throw new AuthenticationError("No OTP request found");
      }

      if (user.otp_expires_at! < new Date()) {
        throw new AuthenticationError("OTP expired");
      }

      // Verify OTP
      if (!verifyOTP(otpCode, user.otp_token)) {
        throw new AuthenticationError("Invalid OTP");
      }

      // Mark as verified and clear OTP
      user.otp_verified = true;
      user.otp_token = null;
      user.otp_expires_at = null;
      await this.userRepository.save(user);

      // Generate JWT tokens
      const tokens = this.generateTokens({
        userId: user.id,
        phone_number: user.phone_number,
        role: user.role,
      });

      return {
        ...tokens,
        user_id: user.id,
      };
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError("OTP verification failed", 500);
    }
  }

  /**
   * Refresh JWT token using refresh token
   */
  async refreshToken(refreshToken: string): Promise<AuthTokens> {
    try {
      const payload = jwt.verify(refreshToken, JWT_SECRET) as JWTPayload;

      const user = await this.userRepository.findOne({
        where: { id: payload.userId },
      });

      if (!user || !user.is_active) {
        throw new AuthenticationError("User not found or inactive");
      }

      const tokens = this.generateTokens(payload);

      return {
        ...tokens,
        user_id: user.id,
      };
    } catch (error) {
      if (error instanceof jwt.JsonWebTokenError) {
        throw new AuthenticationError("Invalid refresh token");
      }
      throw new AppError("Token refresh failed", 500);
    }
  }

  /**
   * Register dashboard user (admin/officer)
   */
  async registerDashboardUser(
    phone: string,
    email: string,
    fullName: string,
    password: string,
    role: UserRole
  ): Promise<{ user_id: string; message: string }> {
    try {
      const formattedPhone = formatPhoneNumber(phone);

      // Check if user exists
      const existingUser = await this.userRepository.findOne({
        where: { phone_number: formattedPhone },
      });

      if (existingUser) {
        throw new ConflictError("User with this phone number already exists");
      }

      // Hash password
      const passwordHash = await bcrypt.hash(password, 10);

      // Create user
      const user = this.userRepository.create({
        phone_number: formattedPhone,
        email,
        full_name: fullName,
        password_hash: passwordHash,
        role,
        otp_verified: true, // Dashboard users don't need OTP
      });

      await this.userRepository.save(user);

      return {
        user_id: user.id,
        message: "User registered successfully",
      };
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError("User registration failed", 500);
    }
  }

  /**
   * Login dashboard user with email + password
   */
  async loginDashboardUser(email: string, password: string): Promise<AuthTokens> {
    try {
      const user = await this.userRepository.findOne({
        where: { email },
      });

      if (!user || !user.password_hash) {
        throw new AuthenticationError("Invalid email or password");
      }

      const isPasswordValid = await bcrypt.compare(password, user.password_hash);
      if (!isPasswordValid) {
        throw new AuthenticationError("Invalid email or password");
      }

      if (!user.is_active) {
        throw new AuthenticationError("User account is inactive");
      }

      const tokens = this.generateTokens({
        userId: user.id,
        phone_number: user.phone_number,
        role: user.role,
      });

      return {
        ...tokens,
        user_id: user.id,
      };
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError("Login failed", 500);
    }
  }

  /**
   * Generate JWT tokens (access + refresh)
   */
  private generateTokens(payload: JWTPayload): { access_token: string; refresh_token: string; expires_in: number } {
    const accessToken = jwt.sign(payload, JWT_SECRET, {
      expiresIn: JWT_EXPIRY,
    });

    const refreshToken = jwt.sign(payload, JWT_SECRET, {
      expiresIn: JWT_REFRESH_EXPIRY,
    });

    // Decode to get expiry
    const decoded = jwt.decode(accessToken) as any;
    const expiresIn = decoded.exp ? decoded.exp - Math.floor(Date.now() / 1000) : 0;

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      expires_in: expiresIn,
    };
  }

  /**
   * Verify JWT token
   */
  verifyToken(token: string): JWTPayload {
    try {
      return jwt.verify(token, JWT_SECRET) as JWTPayload;
    } catch (error) {
      if (error instanceof jwt.JsonWebTokenError) {
        throw new AuthenticationError("Invalid or expired token");
      }
      throw new AppError("Token verification failed", 500);
    }
  }

  /**
   * Get user by ID
   */
  async getUserById(userId: string): Promise<User> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
    });

    if (!user) {
      throw new AppError("User not found", 404);
    }

    return user;
  }
}

export default new AuthService();
