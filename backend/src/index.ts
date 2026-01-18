import "reflect-metadata";
import express, { Express, Request, Response, NextFunction } from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import dotenv from "dotenv";
import { AppDataSource } from "./database";
import authRoutes from "./routes/auth";
import reportRoutes from "./routes/reports";
import caseRoutes from "./routes/cases";
import { AppError } from "./utils/errors";

// Load environment variables
dotenv.config();

const app: Express = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan("dev"));
app.use(express.json());
app.use(express.urlencoded({ limit: "50mb", extended: true }));

// Health check endpoint
app.get("/health", (req: Request, res: Response) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// API v1 routes
app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/reports", reportRoutes);
app.use("/api/v1/cases", caseRoutes);

app.use("/api/v1/ussd", (req: Request, res: Response) => {
  res.status(501).json({ error: "USSD routes not yet implemented" });
});

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({ error: "Route not found" });
});

// Error handler
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error(err);

  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      error: err.message,
      ...(process.env.NODE_ENV === "development" && { stack: err.stack }),
    });
  } else {
    res.status(500).json({
      error: err.message || "Internal server error",
      ...(process.env.NODE_ENV === "development" && { stack: err.stack }),
    });
  }
});

// Initialize database and start server
AppDataSource.initialize()
  .then(() => {
    console.log("✓ Database connection established");

    app.listen(PORT, () => {
      console.log(`✓ Server running on http://localhost:${PORT}`);
      console.log(`✓ Environment: ${process.env.NODE_ENV || "development"}`);
    });
  })
  .catch((error) => {
    console.error("✗ Database connection failed:", error);
    process.exit(1);
  });

export default app;

// Initialize database and start server
AppDataSource.initialize()
  .then(() => {
    console.log("✓ Database connection established");

    app.listen(PORT, () => {
      console.log(`✓ Server running on http://localhost:${PORT}`);
      console.log(`✓ Environment: ${process.env.NODE_ENV || "development"}`);
    });
  })
  .catch((error) => {
    console.error("✗ Database connection failed:", error);
    process.exit(1);
  });

export default app;
