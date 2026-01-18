import { Request, Response, NextFunction } from "express";
import Joi from "joi";
import { AppError } from "../utils/errors";

/**
 * Validation middleware factory
 */
export function validateRequest(schema: Joi.ObjectSchema) {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      const { error, value } = schema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true,
      });

      if (error) {
        const messages = error.details.map((detail) => detail.message).join(", ");
        throw new AppError(messages, 400);
      }

      req.body = value;
      next();
    } catch (err) {
      if (err instanceof AppError) {
        res.status(err.statusCode).json({ error: err.message });
      } else {
        res.status(400).json({ error: "Validation failed" });
      }
    }
  };
}
