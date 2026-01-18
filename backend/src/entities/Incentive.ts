import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index, ManyToOne, JoinColumn } from "typeorm";
import { User } from "./User";
import { Case } from "./Case";
import { Report } from "./Report";

export enum IncentiveStatus {
  PENDING = "pending", // Report submitted, awaiting approval
  EARNED = "earned", // Case approved, points awarded
  REDEEMED = "redeemed", // User redeemed reward
}

export enum RewardType {
  DATA_BUNDLE = "data_bundle",
  CASH_TOKEN = "cash_token",
  UTILITY_CREDIT = "utility_credit",
}

@Entity("incentives")
@Index(["user_id"])
@Index(["report_id"])
@Index(["status"])
@Index(["created_at"])
export class Incentive {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column({ type: "uuid" })
  user_id: string;

  @Column({ type: "uuid" })
  report_id: string;

  @Column({ type: "uuid", nullable: true })
  case_id: string;

  @Column({ type: "integer", default: 0 })
  points: number; // Only non-zero when status = 'earned'

  @Column({ type: "enum", enum: IncentiveStatus, default: IncentiveStatus.PENDING })
  status: IncentiveStatus;

  @Column({ type: "enum", enum: RewardType, nullable: true })
  reward_type: RewardType; // Only set when status = 'redeemed'

  @Column({ type: "timestamp", nullable: true })
  redeem_date: Date;

  @Column({ type: "jsonb", nullable: true })
  audit_log: Array<{
    action: string;
    timestamp: Date;
    performed_by: string; // User ID
    details?: any;
  }>;

  @CreateDateColumn()
  created_at: Date;

  // Relations
  @ManyToOne(() => User, (user) => user.incentives, { onDelete: "CASCADE" })
  @JoinColumn({ name: "user_id" })
  user: User;

  @ManyToOne(() => Report, { onDelete: "CASCADE" })
  @JoinColumn({ name: "report_id" })
  report: Report;

  @ManyToOne(() => Case, (c) => c.incentives, { nullable: true, onDelete: "CASCADE" })
  @JoinColumn({ name: "case_id" })
  case: Case;
}
