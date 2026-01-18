import Joi from "joi";

/**
 * Validation schemas for API endpoints
 */

export const phoneNumberSchema = Joi.string()
  .pattern(/^\+?[0-9\s\-()]{10,}$/)
  .required()
  .messages({
    "string.pattern.base": "Invalid phone number format",
  });

export const otpSchema = Joi.string().length(6).pattern(/^[0-9]+$/).required().messages({
  "string.length": "OTP must be 6 digits",
  "string.pattern.base": "OTP must contain only digits",
});

export const coordinatesSchema = {
  latitude: Joi.number().min(-90).max(90).required(),
  longitude: Joi.number().min(-180).max(180).required(),
};

export const reportCategorySchema = Joi.string()
  .valid("plastic_dumping", "gutter_dumping", "open_defecation", "construction_waste")
  .required();

export const createReportSchema = Joi.object({
  category: reportCategorySchema,
  latitude: coordinatesSchema.latitude,
  longitude: coordinatesSchema.longitude,
  gps_accuracy: Joi.number().positive().optional(),
  captured_at: Joi.date().iso().required(),
  description: Joi.string().max(1000).optional(),
  anonymous: Joi.boolean().default(false),
});

export const approveReportSchema = Joi.object({
  notes: Joi.string().max(1000).optional(),
  assigned_to: Joi.string().uuid().required(),
});

export const rejectReportSchema = Joi.object({
  reason: Joi.string().max(1000).required(),
});

export const ussdMenuSchema = Joi.object({
  phone_number: phoneNumberSchema,
  session_id: Joi.string().uuid().required(),
  user_input: Joi.string().required(),
});
