import { Request, Response, NextFunction } from "express";
import { AuthService, JWTPayload } from "../services/AuthService";
import { AppError } from "../utils/errors";

export interface AuthRequest extends Request {
  user?: JWTPayload;
}

/**
 * Middleware to verify JWT token in Authorization header
 */
export function authMiddleware(req: AuthRequest, res: Response, next: NextFunction): void {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      throw new AppError("Missing or invalid Authorization header", 401);
    }

    const token = authHeader.substring(7);
    const payload = AuthService.verifyToken(token);

    req.user = payload;
    next();
  } catch (error) {
    if (error instanceof AppError) {
      res.status(error.statusCode).json({ error: error.message });
    } else {
      res.status(500).json({ error: "Authentication failed" });
    }
  }
}

/**
 * Middleware to verify user role
 */
export function roleMiddleware(...allowedRoles: string[]) {
  return (req: AuthRequest, res: Response, next: NextFunction): void => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      res.status(403).json({ error: "Access denied" });
      return;
    }
    next();
  };
}
