import "reflect-metadata";
import { AppDataSource } from "../database";
import CaseService from "../services/CaseService";
import AuthService from "../services/AuthService";
import ReportService from "../services/ReportService";
import { UserRole } from "../entities/User";
import { ReportCategory } from "../entities/Report";
import { CaseStatus } from "../entities/Case";

/**
 * Integration test: Full case workflow
 * 1. Citizen submits report
 * 2. Admin approves report and assigns officer
 * 3. Officer completes case
 * 4. Verify incentive points awarded
 */
describe("Case Workflow", () => {
  beforeAll(async () => {
    if (!AppDataSource.isInitialized) {
      await AppDataSource.initialize();
    }
  });

  afterAll(async () => {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
    }
  });

  it("should award points when case approved", async () => {
    // 1. Create citizen and submit report
    const citizenResult = await AuthService.requestOTP("+233501234567");
    expect(citizenResult.otp_expires_in).toBeGreaterThan(0);

    // 2. Create admin user
    const adminUser = await AuthService.registerDashboardUser(
      "+233502234567",
      "admin@example.com",
      "Admin User",
      "SecurePassword123",
      UserRole.ASSEMBLY_ADMIN
    );

    // 3. Create enforcement officer
    const officerUser = await AuthService.registerDashboardUser(
      "+233503234567",
      "officer@example.com",
      "Officer User",
      "SecurePassword123",
      UserRole.ENFORCEMENT_OFFICER
    );

    // 4. Simulate citizen submitting report
    const reportResult = await ReportService.createReport(adminUser.user_id, {
      category: ReportCategory.PLASTIC_DUMPING,
      latitude: 5.6037,
      longitude: -0.187,
      gps_accuracy: 15,
      captured_at: new Date().toISOString(),
      description: "Plastic dumping near market",
      anonymous: false,
    });

    expect(reportResult.case_status).toBe(CaseStatus.SUBMITTED);
    expect(reportResult.points_earned).toBe(0); // Not yet approved

    // 5. Admin approves case
    const approvedCase = await CaseService.approveCase(reportResult.id, adminUser.user_id, {
      notes: "Verified violation",
      assigned_to: officerUser.user_id,
    });

    expect(approvedCase.status).toBe(CaseStatus.APPROVED);
    expect(approvedCase.assigned_to).toBe(officerUser.user_id);

    // 6. Verify incentive points awarded
    const updatedReport = await ReportService.getReport(reportResult.id);
    expect(updatedReport.points_earned).toBeGreaterThan(0);
  });

  it("should not award points when case rejected", async () => {
    const citizenPhone = "+233504234567";

    // Create citizen
    const citizenResult = await AuthService.requestOTP(citizenPhone);
    expect(citizenResult.otp_expires_in).toBeGreaterThan(0);

    // Create admin
    const adminUser = await AuthService.registerDashboardUser(
      "+233505234567",
      "admin2@example.com",
      "Admin User 2",
      "SecurePassword123",
      UserRole.ASSEMBLY_ADMIN
    );

    // Submit report
    const reportResult = await ReportService.createReport(adminUser.user_id, {
      category: ReportCategory.GUTTER_DUMPING,
      latitude: 5.605,
      longitude: -0.188,
      captured_at: new Date().toISOString(),
      description: "Gutter contamination",
      anonymous: true,
    });

    expect(reportResult.points_earned).toBe(0);

    // Admin rejects case
    const rejectedCase = await CaseService.rejectCase(reportResult.id, adminUser.user_id, {
      reason: "Insufficient evidence",
    });

    expect(rejectedCase.status).toBe(CaseStatus.REJECTED);

    // Verify no points awarded
    const updatedReport = await ReportService.getReport(reportResult.id);
    expect(updatedReport.points_earned).toBe(0);
  });
});
