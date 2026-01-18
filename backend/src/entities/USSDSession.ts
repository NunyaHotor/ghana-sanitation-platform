import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from "typeorm";

@Entity("ussd_sessions")
@Index(["phone_number"])
@Index(["created_at"])
export class USSDSession {
  @PrimaryGeneratedColumn("uuid")
  session_id: string;

  @Column({ type: "varchar", length: 20 })
  phone_number: string; // Format: +233xxxxxxxxx

  @Column({ type: "varchar", length: 50, default: "main_menu" })
  menu_state: string; // Current menu state in USSD flow

  @Column({ type: "uuid", nullable: true })
  report_id: string; // Associated report ID if in progress

  @Column({ type: "varchar", nullable: true })
  upload_token: string; // Token for USSD upload requests

  @CreateDateColumn()
  created_at: Date;

  @Column({ type: "timestamp" })
  expires_at: Date; // Session expiry (5 minutes typical for USSD)
}
