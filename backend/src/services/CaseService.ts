import { AppDataSource } from "../database";
import { Case, CaseStatus, StatusHistoryEntry } from "../entities/Case";
import { Report } from "../entities/Report";
import { Incentive, IncentiveStatus } from "../entities/Incentive";
import { User } from "../entities/User";
import { AppError, NotFoundError, ValidationError, AuthorizationError } from "../utils/errors";
import { calculateReportPoints } from "../utils/helpers";

export interface ApproveReportInput {
  notes?: string;
  assigned_to: string; // Officer ID
}

export interface RejectReportInput {
  reason: string;
}

export interface CaseResponse {
  id: string;
  report_id: string;
  status: CaseStatus;
  assigned_to?: string;
  approved_by?: string;
  approval_notes?: string;
  approved_at?: string;
  completed_at?: string;
  created_at: string;
  updated_at: string;
}

export class CaseService {
  private caseRepository = AppDataSource.getRepository(Case);
  private reportRepository = AppDataSource.getRepository(Report);
  private incentiveRepository = AppDataSource.getRepository(Incentive);
  private userRepository = AppDataSource.getRepository(User);

  /**
   * Get case by ID
   */
  async getCase(caseId: string): Promise<CaseResponse> {
    try {
      const caseRecord = await this.caseRepository.findOne({
        where: { id: caseId },
      });

      if (!caseRecord) {
        throw new NotFoundError("Case", caseId);
      }

      return this.mapCaseToResponse(caseRecord);
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError("Failed to fetch case", 500);
    }
  }

  /**
   * List pending cases with pagination (for authority dashboard)
   */
  async listPendingCases(
    status?: CaseStatus,
    limit: number = 20,
    offset: number = 0
  ): Promise<{ total: number; cases: any[] }> {
    try {
      let query = this.caseRepository.createQueryBuilder("case");

      if (status) {
        query = query.where("case.status = :status", { status });
      } else {
        query = query.where("case.status IN (:...statuses)", {
          statuses: [CaseStatus.SUBMITTED, CaseStatus.APPROVED],
        });
      }

      const total = await query.getCount();

      const cases = await query
        .leftJoinAndSelect("case.report", "report")
        .leftJoinAndSelect("case.approved_by_user", "approver")
        .leftJoinAndSelect("case.assigned_to_user", "assignee")
        .orderBy("case.created_at", "DESC")
        .take(limit)
        .skip(offset)
        .getMany();

      return {
        total,
        cases: cases.map((c) => this.enrichCaseResponse(c)),
      };
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError("Failed to list cases", 500);
    }
  }

  /**
   * Approve a report (case transitions from submitted → approved)
   * Triggers incentive points award
   */
  async approveCase(caseId: string, adminId: string, input: ApproveReportInput): Promise<CaseResponse> {
    try {
      const caseRecord = await this.caseRepository.findOne({
        where: { id: caseId },
        relations: ["report"],
      });

      if (!caseRecord) {
        throw new NotFoundError("Case", caseId);
      }

      if (caseRecord.status !== CaseStatus.SUBMITTED) {
        throw new ValidationError(`Case must be in ${CaseStatus.SUBMITTED} status to approve`);
      }

      // Verify assigned_to user exists
      const assignedUser = await this.userRepository.findOne({
        where: { id: input.assigned_to },
      });

      if (!assignedUser) {
        throw new NotFoundError("User", input.assigned_to);
      }

      // Update case
      caseRecord.status = CaseStatus.APPROVED;
      caseRecord.assigned_to = input.assigned_to;
      caseRecord.approved_by = adminId;
      caseRecord.approval_notes = input.notes;
      caseRecord.approved_at = new Date();

      // Add to status history
      const historyEntry: StatusHistoryEntry = {
        status: CaseStatus.APPROVED,
        changed_by: adminId,
        timestamp: new Date(),
        reason: input.notes,
      };

      caseRecord.status_history = [...caseRecord.status_history, historyEntry];

      await this.caseRepository.save(caseRecord);

      // Award points to citizen
      const incentive = await this.incentiveRepository.findOne({
        where: { case_id: caseId },
      });

      if (incentive) {
        incentive.points = calculateReportPoints();
        incentive.status = IncentiveStatus.EARNED;

        // Add audit log
        const auditEntry = {
          action: "points_awarded",
          timestamp: new Date(),
          performed_by: adminId,
          details: { points: incentive.points },
        };

        incentive.audit_log = [...(incentive.audit_log || []), auditEntry];

        await this.incentiveRepository.save(incentive);
      }

      return this.mapCaseToResponse(caseRecord);
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError("Failed to approve case", 500);
    }
  }

  /**
   * Reject a report (case transitions from submitted → rejected)
   */
  async rejectCase(caseId: string, adminId: string, input: RejectReportInput): Promise<CaseResponse> {
    try {
      const caseRecord = await this.caseRepository.findOne({
        where: { id: caseId },
      });

      if (!caseRecord) {
        throw new NotFoundError("Case", caseId);
      }

      if (caseRecord.status !== CaseStatus.SUBMITTED) {
        throw new ValidationError(`Case must be in ${CaseStatus.SUBMITTED} status to reject`);
      }

      caseRecord.status = CaseStatus.REJECTED;
      caseRecord.approved_by = adminId;
      caseRecord.approval_notes = input.reason;
      caseRecord.approved_at = new Date();

      const historyEntry: StatusHistoryEntry = {
        status: CaseStatus.REJECTED,
        changed_by: adminId,
        timestamp: new Date(),
        reason: input.reason,
      };

      caseRecord.status_history = [...caseRecord.status_history, historyEntry];

      await this.caseRepository.save(caseRecord);

      // Mark incentive as rejected (points stay 0)
      const incentive = await this.incentiveRepository.findOne({
        where: { case_id: caseId },
      });

      if (incentive) {
        incentive.status = IncentiveStatus.PENDING; // Stays pending, no reward
        const auditEntry = {
          action: "case_rejected",
          timestamp: new Date(),
          performed_by: adminId,
          details: { reason: input.reason },
        };

        incentive.audit_log = [...(incentive.audit_log || []), auditEntry];

        await this.incentiveRepository.save(incentive);
      }

      return this.mapCaseToResponse(caseRecord);
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError("Failed to reject case", 500);
    }
  }

  /**
   * Mark case as completed by enforcement officer
   */
  async completeCase(caseId: string, officerId: string, evidenceUrl: string): Promise<CaseResponse> {
    try {
      const caseRecord = await this.caseRepository.findOne({
        where: { id: caseId },
      });

      if (!caseRecord) {
        throw new NotFoundError("Case", caseId);
      }

      // Verify officer is assigned to this case
      if (caseRecord.assigned_to !== officerId) {
        throw new AuthorizationError("You are not assigned to this case");
      }

      if (caseRecord.status !== CaseStatus.ASSIGNED) {
        throw new ValidationError(`Case must be in ${CaseStatus.ASSIGNED} status to complete`);
      }

      caseRecord.status = CaseStatus.COMPLETED;
      caseRecord.completed_at = new Date();
      caseRecord.completion_evidence_url = evidenceUrl;

      const historyEntry: StatusHistoryEntry = {
        status: CaseStatus.COMPLETED,
        changed_by: officerId,
        timestamp: new Date(),
        reason: "Enforcement completed",
      };

      caseRecord.status_history = [...caseRecord.status_history, historyEntry];

      await this.caseRepository.save(caseRecord);

      return this.mapCaseToResponse(caseRecord);
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError("Failed to complete case", 500);
    }
  }

  /**
   * Helper to map case to response format
   */
  private mapCaseToResponse(caseRecord: Case): CaseResponse {
    return {
      id: caseRecord.id,
      report_id: caseRecord.report_id,
      status: caseRecord.status,
      assigned_to: caseRecord.assigned_to,
      approved_by: caseRecord.approved_by,
      approval_notes: caseRecord.approval_notes,
      approved_at: caseRecord.approved_at?.toISOString(),
      completed_at: caseRecord.completed_at?.toISOString(),
      created_at: caseRecord.created_at.toISOString(),
      updated_at: caseRecord.updated_at.toISOString(),
    };
  }

  /**
   * Helper to enrich case with related data
   */
  private enrichCaseResponse(caseRecord: Case): any {
    return {
      ...this.mapCaseToResponse(caseRecord),
      report: caseRecord.report
        ? {
            category: caseRecord.report.category,
            latitude: caseRecord.report.latitude,
            longitude: caseRecord.report.longitude,
            captured_at: caseRecord.report.captured_at.toISOString(),
          }
        : null,
      approved_by_name: caseRecord.approved_by_user?.full_name,
      assigned_to_name: caseRecord.assigned_to_user?.full_name,
    };
  }
}

export default new CaseService();
