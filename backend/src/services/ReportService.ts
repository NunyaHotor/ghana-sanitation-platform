import { AppDataSource } from "../database";
import { Report, ReportCategory } from "../entities/Report";
import { Case, CaseStatus } from "../entities/Case";
import { Incentive, IncentiveStatus } from "../entities/Incentive";
import { AppError, NotFoundError, ValidationError } from "../utils/errors";
import { validateCoordinates, validateISO8601, calculateFileChecksum } from "../utils/helpers";

export interface CreateReportInput {
  category: ReportCategory;
  latitude: number;
  longitude: number;
  gps_accuracy?: number;
  captured_at: string; // ISO 8601
  photo_urls?: string[];
  video_url?: string;
  description?: string;
  anonymous?: boolean;
}

export interface ReportResponse {
  id: string;
  category: string;
  latitude: number;
  longitude: number;
  captured_at: string;
  status: string;
  case_status?: string;
  points_earned?: number;
  created_at: string;
}

export class ReportService {
  private reportRepository = AppDataSource.getRepository(Report);
  private caseRepository = AppDataSource.getRepository(Case);
  private incentiveRepository = AppDataSource.getRepository(Incentive);

  /**
   * Create a new report (immutable after creation)
   */
  async createReport(userId: string, input: CreateReportInput): Promise<ReportResponse> {
    try {
      // Validate coordinates
      if (!validateCoordinates(input.latitude, input.longitude)) {
        throw new ValidationError("Invalid GPS coordinates");
      }

      // Validate timestamp
      if (!validateISO8601(input.captured_at)) {
        throw new ValidationError("Invalid captured_at timestamp (must be ISO 8601)");
      }

      // Ensure captured_at is not in the future
      if (new Date(input.captured_at) > new Date()) {
        throw new ValidationError("captured_at cannot be in the future");
      }

      // Create report
      const report = this.reportRepository.create({
        user_id: userId,
        category: input.category,
        latitude: input.latitude,
        longitude: input.longitude,
        gps_accuracy: input.gps_accuracy,
        captured_at: new Date(input.captured_at),
        photo_urls: input.photo_urls,
        video_url: input.video_url,
        description: input.description,
        anonymous: input.anonymous ?? false,
      });

      await this.reportRepository.save(report);

      // Create associated case
      const caseRecord = this.caseRepository.create({
        report_id: report.id,
        status: CaseStatus.SUBMITTED,
      });

      await this.caseRepository.save(caseRecord);

      // Create incentive record (points pending until approval)
      const incentive = this.incentiveRepository.create({
        user_id: userId,
        report_id: report.id,
        case_id: caseRecord.id,
        points: 0,
        status: IncentiveStatus.PENDING,
      });

      await this.incentiveRepository.save(incentive);

      return this.mapReportToResponse(report, caseRecord, incentive);
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError("Failed to create report", 500);
    }
  }

  /**
   * Get report by ID with case status and incentive info
   */
  async getReport(reportId: string, userId?: string): Promise<ReportResponse> {
    try {
      const report = await this.reportRepository.findOne({
        where: { id: reportId },
      });

      if (!report) {
        throw new NotFoundError("Report", reportId);
      }

      const caseRecord = await this.caseRepository.findOne({
        where: { report_id: reportId },
      });

      if (!caseRecord) {
        throw new AppError("Case not found for report", 500);
      }

      const incentive = await this.incentiveRepository.findOne({
        where: { report_id: reportId },
      });

      return this.mapReportToResponse(report, caseRecord, incentive || null);
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError("Failed to fetch report", 500);
    }
  }

  /**
   * List reports with pagination and filters
   */
  async listReports(
    userId: string,
    limit: number = 20,
    offset: number = 0,
    filters?: {
      category?: ReportCategory;
      status?: CaseStatus;
      from_date?: string;
      to_date?: string;
    }
  ): Promise<{ total: number; reports: ReportResponse[] }> {
    try {
      let query = this.reportRepository.createQueryBuilder("report").where("report.user_id = :userId", { userId });

      if (filters?.category) {
        query = query.andWhere("report.category = :category", { category: filters.category });
      }

      if (filters?.from_date) {
        query = query.andWhere("report.created_at >= :fromDate", { fromDate: new Date(filters.from_date) });
      }

      if (filters?.to_date) {
        query = query.andWhere("report.created_at <= :toDate", { toDate: new Date(filters.to_date) });
      }

      const total = await query.getCount();

      const reports = await query.orderBy("report.created_at", "DESC").take(limit).skip(offset).getMany();

      const enrichedReports = await Promise.all(
        reports.map(async (report) => {
          const caseRecord = await this.caseRepository.findOne({
            where: { report_id: report.id },
          });
          const incentive = await this.incentiveRepository.findOne({
            where: { report_id: report.id },
          });
          return this.mapReportToResponse(report, caseRecord!, incentive);
        })
      );

      return { total, reports: enrichedReports };
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError("Failed to list reports", 500);
    }
  }

  /**
   * Get reports by location (for heatmap/analytics)
   */
  async getReportsByLocation(
    minLat: number,
    maxLat: number,
    minLon: number,
    maxLon: number,
    category?: ReportCategory
  ): Promise<any[]> {
    try {
      let query = this.reportRepository.createQueryBuilder("report").where(
        "report.latitude BETWEEN :minLat AND :maxLat AND report.longitude BETWEEN :minLon AND :maxLon",
        { minLat, maxLat, minLon, maxLon }
      );

      if (category) {
        query = query.andWhere("report.category = :category", { category });
      }

      return await query.select("report.latitude", "lat").addSelect("report.longitude", "lon").addSelect("COUNT(*)", "count").groupBy("report.latitude, report.longitude").getRawMany();
    } catch (error) {
      throw new AppError("Failed to fetch location data", 500);
    }
  }

  /**
   * Helper to map report to response format
   */
  private mapReportToResponse(report: Report, caseRecord: Case, incentive: Incentive | null): ReportResponse {
    return {
      id: report.id,
      category: report.category,
      latitude: parseFloat(report.latitude.toString()),
      longitude: parseFloat(report.longitude.toString()),
      captured_at: report.captured_at.toISOString(),
      status: "submitted",
      case_status: caseRecord.status,
      points_earned: incentive?.points || 0,
      created_at: report.created_at.toISOString(),
    };
  }
}

export default new ReportService();
