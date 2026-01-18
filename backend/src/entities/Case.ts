import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index, ManyToOne, JoinColumn, OneToMany } from "typeorm";
import { Report } from "./Report";
import { User } from "./User";
import { Incentive } from "./Incentive";

export enum CaseStatus {
  SUBMITTED = "submitted",
  APPROVED = "approved",
  ASSIGNED = "assigned",
  COMPLETED = "completed",
  REJECTED = "rejected",
}

export interface StatusHistoryEntry {
  status: CaseStatus;
  changed_by: string; // User ID
  timestamp: Date;
  reason?: string;
}

@Entity("cases")
@Index(["report_id"], { unique: true })
@Index(["status"])
@Index(["created_at"])
@Index(["assigned_to"])
export class Case {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column({ type: "uuid" })
  report_id: string;

  @Column({ type: "enum", enum: CaseStatus, default: CaseStatus.SUBMITTED })
  status: CaseStatus;

  @Column({ type: "uuid", nullable: true })
  assigned_to: string; // Enforcement officer ID

  @Column({ type: "uuid", nullable: true })
  approved_by: string; // Admin ID who approved

  @Column({ type: "text", nullable: true })
  approval_notes: string;

  @Column({ type: "timestamp", nullable: true })
  approved_at: Date;

  @Column({ type: "timestamp", nullable: true })
  completed_at: Date;

  @Column({ type: "varchar", nullable: true })
  completion_evidence_url: string; // URL to evidence of completion

  @Column({ type: "jsonb", default: "[]" })
  status_history: StatusHistoryEntry[]; // Audit trail

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;

  // Relations
  @ManyToOne(() => Report, (report) => report.cases, { onDelete: "CASCADE" })
  @JoinColumn({ name: "report_id" })
  report: Report;

  @ManyToOne(() => User, (user) => user.approved_cases, { nullable: true })
  @JoinColumn({ name: "approved_by" })
  approved_by_user: User;

  @ManyToOne(() => User, (user) => user.assigned_cases, { nullable: true })
  @JoinColumn({ name: "assigned_to" })
  assigned_to_user: User;

  @OneToMany(() => Incentive, (incentive) => incentive.case)
  incentives: Incentive[];
}
