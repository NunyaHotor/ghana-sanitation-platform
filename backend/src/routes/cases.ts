import { Router, Request, Response, NextFunction } from "express";
import Joi from "joi";
import CaseService from "../services/CaseService";
import { authMiddleware, roleMiddleware, AuthRequest } from "../middleware/auth";
import { validateRequest } from "../middleware/validation";
import { approveReportSchema, rejectReportSchema } from "../utils/validation";
import { UserRole } from "../entities/User";
import { CaseStatus } from "../entities/Case";
import { AppError } from "../utils/errors";

const router = Router();

/**
 * GET /api/v1/cases
 * List pending cases (authority dashboard only)
 */
router.get(
  "/",
  authMiddleware,
  roleMiddleware(UserRole.ASSEMBLY_ADMIN),
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const status = req.query.status as CaseStatus | undefined;
      const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
      const offset = parseInt(req.query.offset as string) || 0;

      const { total, cases } = await CaseService.listPendingCases(status, limit, offset);

      res.status(200).json({
        total,
        limit,
        offset,
        cases,
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * GET /api/v1/cases/:caseId
 * Get case details
 */
router.get(
  "/:caseId",
  authMiddleware,
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const { caseId } = req.params;
      const caseRecord = await CaseService.getCase(caseId);
      res.status(200).json(caseRecord);
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /api/v1/cases/:caseId/approve
 * Approve case and assign to enforcement officer
 * (authority admin only)
 */
router.post(
  "/:caseId/approve",
  authMiddleware,
  roleMiddleware(UserRole.ASSEMBLY_ADMIN),
  validateRequest(approveReportSchema),
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      if (!req.user) {
        throw new AppError("User not authenticated", 401);
      }

      const { caseId } = req.params;
      const caseRecord = await CaseService.approveCase(caseId, req.user.userId, req.body);

      res.status(200).json({
        message: "Case approved and officer assigned",
        status: "approved",
        officer_notified: true, // TODO: implement notification
        ...caseRecord,
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /api/v1/cases/:caseId/reject
 * Reject case with reason
 * (authority admin only)
 */
router.post(
  "/:caseId/reject",
  authMiddleware,
  roleMiddleware(UserRole.ASSEMBLY_ADMIN),
  validateRequest(rejectReportSchema),
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      if (!req.user) {
        throw new AppError("User not authenticated", 401);
      }

      const { caseId } = req.params;
      const caseRecord = await CaseService.rejectCase(caseId, req.user.userId, req.body);

      res.status(200).json({
        message: "Case rejected",
        status: "rejected",
        user_notified: true, // TODO: implement notification
        ...caseRecord,
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /api/v1/cases/:caseId/complete
 * Mark case as completed by enforcement officer
 * (enforcement officer only)
 */
router.post(
  "/:caseId/complete",
  authMiddleware,
  roleMiddleware(UserRole.ENFORCEMENT_OFFICER),
  validateRequest(
    Joi.object({
      completion_evidence_url: Joi.string().uri().required(),
    })
  ),
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      if (!req.user) {
        throw new AppError("User not authenticated", 401);
      }

      const { caseId } = req.params;
      const { completion_evidence_url } = req.body;

      const caseRecord = await CaseService.completeCase(caseId, req.user.userId, completion_evidence_url);

      res.status(200).json({
        message: "Case marked as completed",
        status: "completed",
        ...caseRecord,
      });
    } catch (error) {
      next(error);
    }
  }
);

export default router;
