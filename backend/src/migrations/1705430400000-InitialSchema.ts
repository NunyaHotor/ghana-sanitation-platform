import { MigrationInterface, QueryRunner, Table, TableIndex, TableForeignKey } from "typeorm";

export class InitialSchema1705430400000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create ENUM types
    await queryRunner.query(`
      CREATE TYPE user_role_enum AS ENUM('citizen', 'enforcement_officer', 'assembly_admin');
    `);

    await queryRunner.query(`
      CREATE TYPE report_category_enum AS ENUM(
        'plastic_dumping',
        'gutter_dumping',
        'open_defecation',
        'construction_waste'
      );
    `);

    await queryRunner.query(`
      CREATE TYPE case_status_enum AS ENUM(
        'submitted',
        'approved',
        'assigned',
        'completed',
        'rejected'
      );
    `);

    await queryRunner.query(`
      CREATE TYPE incentive_status_enum AS ENUM('pending', 'earned', 'redeemed');
    `);

    await queryRunner.query(`
      CREATE TYPE reward_type_enum AS ENUM('data_bundle', 'cash_token', 'utility_credit');
    `);

    // Users table
    await queryRunner.createTable(
      new Table({
        name: "users",
        columns: [
          { name: "id", type: "uuid", isPrimary: true, generationStrategy: "uuid", default: "gen_random_uuid()" },
          { name: "phone_number", type: "varchar", length: "20", isUnique: true },
          { name: "full_name", type: "varchar", length: "255", isNullable: true },
          { name: "email", type: "varchar", length: "255", isNullable: true },
          { name: "role", type: "user_role_enum", default: "'citizen'" },
          { name: "otp_token", type: "varchar", isNullable: true },
          { name: "otp_expires_at", type: "timestamp", isNullable: true },
          { name: "otp_verified", type: "boolean", default: false },
          { name: "password_hash", type: "varchar", isNullable: true },
          { name: "anonymous", type: "boolean", default: true },
          { name: "is_active", type: "boolean", default: true },
          { name: "created_at", type: "timestamp", default: "CURRENT_TIMESTAMP" },
          { name: "updated_at", type: "timestamp", default: "CURRENT_TIMESTAMP" },
        ],
      })
    );

    await queryRunner.createIndex("users", new TableIndex({ columnNames: ["phone_number"] }));
    await queryRunner.createIndex("users", new TableIndex({ columnNames: ["email"] }));
    await queryRunner.createIndex("users", new TableIndex({ columnNames: ["created_at"] }));

    // Reports table
    await queryRunner.createTable(
      new Table({
        name: "reports",
        columns: [
          { name: "id", type: "uuid", isPrimary: true, generationStrategy: "uuid", default: "gen_random_uuid()" },
          { name: "user_id", type: "uuid" },
          { name: "category", type: "report_category_enum" },
          { name: "latitude", type: "numeric", precision: 10, scale: 8 },
          { name: "longitude", type: "numeric", precision: 11, scale: 8 },
          { name: "gps_accuracy", type: "integer", isNullable: true },
          { name: "captured_at", type: "timestamp" },
          { name: "photo_urls", type: "text", isArray: true, isNullable: true },
          { name: "video_url", type: "varchar", isNullable: true },
          { name: "description", type: "text", isNullable: true },
          { name: "anonymous", type: "boolean", default: false },
          { name: "photo_checksum", type: "varchar", length: "32", isNullable: true },
          { name: "video_checksum", type: "varchar", length: "32", isNullable: true },
          { name: "created_at", type: "timestamp", default: "CURRENT_TIMESTAMP" },
        ],
      })
    );

    await queryRunner.createIndex("reports", new TableIndex({ columnNames: ["user_id"] }));
    await queryRunner.createIndex("reports", new TableIndex({ columnNames: ["created_at"] }));
    await queryRunner.createIndex("reports", new TableIndex({ columnNames: ["latitude", "longitude"] }));
    await queryRunner.createIndex("reports", new TableIndex({ columnNames: ["category"] }));

    // Cases table
    await queryRunner.createTable(
      new Table({
        name: "cases",
        columns: [
          { name: "id", type: "uuid", isPrimary: true, generationStrategy: "uuid", default: "gen_random_uuid()" },
          { name: "report_id", type: "uuid", isUnique: true },
          { name: "status", type: "case_status_enum", default: "'submitted'" },
          { name: "assigned_to", type: "uuid", isNullable: true },
          { name: "approved_by", type: "uuid", isNullable: true },
          { name: "approval_notes", type: "text", isNullable: true },
          { name: "approved_at", type: "timestamp", isNullable: true },
          { name: "completed_at", type: "timestamp", isNullable: true },
          { name: "completion_evidence_url", type: "varchar", isNullable: true },
          { name: "status_history", type: "jsonb", default: "'[]'" },
          { name: "created_at", type: "timestamp", default: "CURRENT_TIMESTAMP" },
          { name: "updated_at", type: "timestamp", default: "CURRENT_TIMESTAMP" },
        ],
      })
    );

    await queryRunner.createIndex("cases", new TableIndex({ columnNames: ["report_id"] }));
    await queryRunner.createIndex("cases", new TableIndex({ columnNames: ["status"] }));
    await queryRunner.createIndex("cases", new TableIndex({ columnNames: ["created_at"] }));
    await queryRunner.createIndex("cases", new TableIndex({ columnNames: ["assigned_to"] }));

    // Incentives table
    await queryRunner.createTable(
      new Table({
        name: "incentives",
        columns: [
          { name: "id", type: "uuid", isPrimary: true, generationStrategy: "uuid", default: "gen_random_uuid()" },
          { name: "user_id", type: "uuid" },
          { name: "report_id", type: "uuid" },
          { name: "case_id", type: "uuid", isNullable: true },
          { name: "points", type: "integer", default: 0 },
          { name: "status", type: "incentive_status_enum", default: "'pending'" },
          { name: "reward_type", type: "reward_type_enum", isNullable: true },
          { name: "redeem_date", type: "timestamp", isNullable: true },
          { name: "audit_log", type: "jsonb", isNullable: true },
          { name: "created_at", type: "timestamp", default: "CURRENT_TIMESTAMP" },
        ],
      })
    );

    await queryRunner.createIndex("incentives", new TableIndex({ columnNames: ["user_id"] }));
    await queryRunner.createIndex("incentives", new TableIndex({ columnNames: ["report_id"] }));
    await queryRunner.createIndex("incentives", new TableIndex({ columnNames: ["status"] }));
    await queryRunner.createIndex("incentives", new TableIndex({ columnNames: ["created_at"] }));

    // USSD Sessions table
    await queryRunner.createTable(
      new Table({
        name: "ussd_sessions",
        columns: [
          { name: "session_id", type: "uuid", isPrimary: true, generationStrategy: "uuid", default: "gen_random_uuid()" },
          { name: "phone_number", type: "varchar", length: "20" },
          { name: "menu_state", type: "varchar", length: "50", default: "'main_menu'" },
          { name: "report_id", type: "uuid", isNullable: true },
          { name: "upload_token", type: "varchar", isNullable: true },
          { name: "created_at", type: "timestamp", default: "CURRENT_TIMESTAMP" },
          { name: "expires_at", type: "timestamp" },
        ],
      })
    );

    await queryRunner.createIndex("ussd_sessions", new TableIndex({ columnNames: ["phone_number"] }));
    await queryRunner.createIndex("ussd_sessions", new TableIndex({ columnNames: ["created_at"] }));

    // Foreign Keys
    await queryRunner.createForeignKey(
      "reports",
      new TableForeignKey({
        columnNames: ["user_id"],
        referencedTableName: "users",
        referencedColumnNames: ["id"],
        onDelete: "CASCADE",
      })
    );

    await queryRunner.createForeignKey(
      "cases",
      new TableForeignKey({
        columnNames: ["report_id"],
        referencedTableName: "reports",
        referencedColumnNames: ["id"],
        onDelete: "CASCADE",
      })
    );

    await queryRunner.createForeignKey(
      "cases",
      new TableForeignKey({
        columnNames: ["approved_by"],
        referencedTableName: "users",
        referencedColumnNames: ["id"],
        onDelete: "SET NULL",
      })
    );

    await queryRunner.createForeignKey(
      "cases",
      new TableForeignKey({
        columnNames: ["assigned_to"],
        referencedTableName: "users",
        referencedColumnNames: ["id"],
        onDelete: "SET NULL",
      })
    );

    await queryRunner.createForeignKey(
      "incentives",
      new TableForeignKey({
        columnNames: ["user_id"],
        referencedTableName: "users",
        referencedColumnNames: ["id"],
        onDelete: "CASCADE",
      })
    );

    await queryRunner.createForeignKey(
      "incentives",
      new TableForeignKey({
        columnNames: ["report_id"],
        referencedTableName: "reports",
        referencedColumnNames: ["id"],
        onDelete: "CASCADE",
      })
    );

    await queryRunner.createForeignKey(
      "incentives",
      new TableForeignKey({
        columnNames: ["case_id"],
        referencedTableName: "cases",
        referencedColumnNames: ["id"],
        onDelete: "CASCADE",
      })
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop foreign keys
    const casesTable = await queryRunner.getTable("cases");
    const caseForeignKeys = casesTable?.foreignKeys || [];
    for (const fk of caseForeignKeys) {
      await queryRunner.dropForeignKey("cases", fk);
    }

    const reportsTable = await queryRunner.getTable("reports");
    const reportForeignKeys = reportsTable?.foreignKeys || [];
    for (const fk of reportForeignKeys) {
      await queryRunner.dropForeignKey("reports", fk);
    }

    const incentivesTable = await queryRunner.getTable("incentives");
    const incentiveForeignKeys = incentivesTable?.foreignKeys || [];
    for (const fk of incentiveForeignKeys) {
      await queryRunner.dropForeignKey("incentives", fk);
    }

    // Drop tables
    await queryRunner.dropTable("ussd_sessions");
    await queryRunner.dropTable("incentives");
    await queryRunner.dropTable("cases");
    await queryRunner.dropTable("reports");
    await queryRunner.dropTable("users");

    // Drop ENUM types
    await queryRunner.query("DROP TYPE user_role_enum");
    await queryRunner.query("DROP TYPE report_category_enum");
    await queryRunner.query("DROP TYPE case_status_enum");
    await queryRunner.query("DROP TYPE incentive_status_enum");
    await queryRunner.query("DROP TYPE reward_type_enum");
  }
}
