import { Router, Request, Response, NextFunction } from "express";
import Joi from "joi";
import ReportService from "../services/ReportService";
import { authMiddleware, AuthRequest } from "../middleware/auth";
import { validateRequest } from "../middleware/validation";
import { createReportSchema } from "../utils/validation";
import { ReportCategory } from "../entities/Report";
import { AppError } from "../utils/errors";

const router = Router();

/**
 * POST /api/v1/reports
 * Create new sanitation violation report
 * Requires authentication
 */
router.post(
  "/",
  authMiddleware,
  validateRequest(createReportSchema),
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      if (!req.user) {
        throw new AppError("User not authenticated", 401);
      }

      const report = await ReportService.createReport(req.user.userId, req.body);

      res.status(201).json({
        report_id: report.id,
        case_id: report.id, // Case ID is same as report ID (one-to-one)
        status: "submitted",
        message: "Report submitted successfully",
        ...report,
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * GET /api/v1/reports/:reportId
 * Get report status and incentive info
 */
router.get("/:reportId", authMiddleware, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw new AppError("User not authenticated", 401);
    }

    const { reportId } = req.params;
    const report = await ReportService.getReport(reportId, req.user.userId);

    res.status(200).json(report);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/reports
 * List user's reports with pagination and filters
 */
router.get(
  "/",
  authMiddleware,
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      if (!req.user) {
        throw new AppError("User not authenticated", 401);
      }

      const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
      const offset = parseInt(req.query.offset as string) || 0;

      const filters = {
        category: req.query.category as ReportCategory | undefined,
        from_date: req.query.from_date as string | undefined,
        to_date: req.query.to_date as string | undefined,
      };

      const { total, reports } = await ReportService.listReports(req.user.userId, limit, offset, filters);

      res.status(200).json({
        total,
        limit,
        offset,
        reports,
      });
    } catch (error) {
      next(error);
    }
  }
);

/**
 * GET /api/v1/reports/heatmap
 * Get report heatmap data by location
 */
router.get(
  "/analytics/heatmap",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { min_lat, max_lat, min_lon, max_lon, category } = req.query;

      if (!min_lat || !max_lat || !min_lon || !max_lon) {
        throw new AppError("Missing required bbox parameters: min_lat, max_lat, min_lon, max_lon", 400);
      }

      const heatmapData = await ReportService.getReportsByLocation(
        parseFloat(min_lat as string),
        parseFloat(max_lat as string),
        parseFloat(min_lon as string),
        parseFloat(max_lon as string),
        category as ReportCategory | undefined
      );

      res.status(200).json({
        violations_by_location: heatmapData.map((point) => [
          parseFloat(point.lat),
          parseFloat(point.lon),
          parseInt(point.count),
        ]),
      });
    } catch (error) {
      next(error);
    }
  }
);

export default router;
