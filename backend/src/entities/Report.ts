import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index, ManyToOne, JoinColumn, OneToMany } from "typeorm";
import { User } from "./User";
import { Case } from "./Case";

export enum ReportCategory {
  PLASTIC_DUMPING = "plastic_dumping",
  GUTTER_DUMPING = "gutter_dumping",
  OPEN_DEFECATION = "open_defecation",
  CONSTRUCTION_WASTE = "construction_waste",
}

@Entity("reports")
@Index(["user_id"])
@Index(["created_at"])
@Index(["latitude", "longitude"])
@Index(["category"])
export class Report {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column({ type: "uuid" })
  user_id: string;

  @Column({ type: "enum", enum: ReportCategory })
  category: ReportCategory;

  @Column({ type: "decimal", precision: 10, scale: 8 })
  latitude: number; // WGS84 decimal degrees

  @Column({ type: "decimal", precision: 11, scale: 8 })
  longitude: number; // WGS84 decimal degrees

  @Column({ type: "integer", nullable: true })
  gps_accuracy: number; // Accuracy in meters; null if unavailable

  @Column({ type: "timestamp" })
  captured_at: Date; // ISO 8601 UTC

  @Column({ type: "simple-array", nullable: true })
  photo_urls: string[]; // Array of uploaded photo URLs

  @Column({ type: "varchar", nullable: true })
  video_url: string; // Single video URL

  @Column({ type: "text", nullable: true })
  description: string;

  @Column({ type: "boolean", default: false })
  anonymous: boolean;

  @Column({ type: "varchar", length: 32, nullable: true })
  photo_checksum: string; // SHA256 checksum for integrity

  @Column({ type: "varchar", length: 32, nullable: true })
  video_checksum: string;

  @CreateDateColumn()
  created_at: Date;

  // No updated_at: reports are immutable after creation

  // Relations
  @ManyToOne(() => User, (user) => user.reports, { onDelete: "CASCADE" })
  @JoinColumn({ name: "user_id" })
  user: User;

  @OneToMany(() => Case, (c) => c.report)
  cases: Case[];
}
