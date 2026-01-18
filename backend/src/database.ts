import "reflect-metadata";
import { DataSource } from "typeorm";
import { User } from "./entities/User";
import { Report } from "./entities/Report";
import { Case } from "./entities/Case";
import { Incentive } from "./entities/Incentive";
import { USSDSession } from "./entities/USSDSession";

export const AppDataSource = new DataSource({
  type: "postgres",
  host: process.env.DB_HOST || "localhost",
  port: parseInt(process.env.DB_PORT || "5432"),
  username: process.env.DB_USERNAME || "postgres",
  password: process.env.DB_PASSWORD || "password",
  database: process.env.DB_NAME || "ghana_sanitation_db",
  synchronize: false, // Use migrations instead
  logging: process.env.NODE_ENV === "development",
  entities: [User, Report, Case, Incentive, USSDSession],
  migrations: ["src/migrations/*.ts"],
  subscribers: ["src/subscribers/*.ts"],
});
