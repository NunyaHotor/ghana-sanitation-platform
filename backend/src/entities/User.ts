import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index, OneToMany } from "typeorm";
import { Report } from "./Report";
import { Case } from "./Case";
import { Incentive } from "./Incentive";

export enum UserRole {
  CITIZEN = "citizen",
  ENFORCEMENT_OFFICER = "enforcement_officer",
  ASSEMBLY_ADMIN = "assembly_admin",
}

@Entity("users")
@Index(["phone_number"], { unique: true })
export class User {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column({ type: "varchar", length: 20 })
  phone_number: string; // Format: +233xxxxxxxxx

  @Column({ type: "varchar", length: 255, nullable: true })
  full_name: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  email: string;

  @Column({ type: "enum", enum: UserRole, default: UserRole.CITIZEN })
  role: UserRole;

  @Column({ type: "varchar", nullable: true })
  otp_token: string; // Hashed OTP

  @Column({ type: "timestamp", nullable: true })
  otp_expires_at: Date;

  @Column({ type: "boolean", default: false })
  otp_verified: boolean;

  @Column({ type: "varchar", nullable: true })
  password_hash: string; // For dashboard users only

  @Column({ type: "boolean", default: true })
  anonymous: boolean; // Citizens can choose to report anonymously

  @Column({ type: "boolean", default: true })
  is_active: boolean;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;

  // Relations
  @OneToMany(() => Report, (report) => report.user)
  reports: Report[];

  @OneToMany(() => Case, (c) => c.approved_by_user)
  approved_cases: Case[];

  @OneToMany(() => Case, (c) => c.assigned_to_user)
  assigned_cases: Case[];

  @OneToMany(() => Incentive, (incentive) => incentive.user)
  incentives: Incentive[];
}
