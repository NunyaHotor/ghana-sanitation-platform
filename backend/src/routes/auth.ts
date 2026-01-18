import { Router, Request, Response, NextFunction } from "express";
import Joi from "joi";
import AuthService from "../services/AuthService";
import { authMiddleware, roleMiddleware, AuthRequest } from "../middleware/auth";
import { validateRequest } from "../middleware/validation";
import { phoneNumberSchema, otpSchema } from "../utils/validation";
import { AppError } from "../utils/errors";
import { UserRole } from "../entities/User";

const router = Router();

/**
 * POST /api/v1/auth/request-otp
 * Request OTP for phone number (citizen registration/login)
 */
router.post(
  "/request-otp",
  validateRequest(
    Joi.object({
      phone_number: phoneNumberSchema,
    })
  ),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { phone_number } = req.body;
      const result = await AuthService.requestOTP(phone_number);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /api/v1/auth/verify-otp
 * Verify OTP and return JWT tokens
 */
router.post(
  "/verify-otp",
  validateRequest(
    Joi.object({
      phone_number: phoneNumberSchema,
      otp_code: otpSchema,
    })
  ),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { phone_number, otp_code } = req.body;
      const tokens = await AuthService.verifyOTP(phone_number, otp_code);
      res.status(200).json(tokens);
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /api/v1/auth/refresh
 * Refresh JWT access token using refresh token
 */
router.post(
  "/refresh",
  validateRequest(
    Joi.object({
      refresh_token: Joi.string().required(),
    })
  ),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { refresh_token } = req.body;
      const tokens = await AuthService.refreshToken(refresh_token);
      res.status(200).json(tokens);
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /api/v1/auth/register-dashboard
 * Register dashboard user (admin/enforcement officer)
 * Only callable by existing admins (TODO: SSO integration)
 */
router.post(
  "/register-dashboard",
  validateRequest(
    Joi.object({
      phone_number: phoneNumberSchema,
      email: Joi.string().email().required(),
      full_name: Joi.string().min(2).max(255).required(),
      password: Joi.string().min(8).required(),
      role: Joi.string().valid(UserRole.ENFORCEMENT_OFFICER, UserRole.ASSEMBLY_ADMIN).required(),
    })
  ),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { phone_number, email, full_name, password, role } = req.body;
      const result = await AuthService.registerDashboardUser(phone_number, email, full_name, password, role);
      res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /api/v1/auth/login-dashboard
 * Login dashboard user with email + password
 */
router.post(
  "/login-dashboard",
  validateRequest(
    Joi.object({
      email: Joi.string().email().required(),
      password: Joi.string().required(),
    })
  ),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { email, password } = req.body;
      const tokens = await AuthService.loginDashboardUser(email, password);
      res.status(200).json(tokens);
    } catch (error) {
      next(error);
    }
  }
);

/**
 * GET /api/v1/auth/me
 * Get current authenticated user info
 */
router.get("/me", authMiddleware, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw new AppError("User not authenticated", 401);
    }

    const user = await AuthService.getUserById(req.user.userId);

    // Don't expose password hash
    const { password_hash, otp_token, ...userInfo } = user;

    res.status(200).json(userInfo);
  } catch (error) {
    next(error);
  }
});

export default router;
