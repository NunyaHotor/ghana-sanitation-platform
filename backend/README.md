# Ghana Sanitation Platform - Backend API

Backend service for the Ghana Sanitation Reporting & Enforcement Platform.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- PostgreSQL 12+
- npm or yarn

### Setup

```bash
# Install dependencies
npm install

# Create .env file from example
cp .env.example .env

# Update .env with your database credentials and API keys

# Run database migrations
npm run migration:run

# Start development server
npm run dev
```

Server will run on `http://localhost:3000`

## 📁 Project Structure

```
src/
├── index.ts              # Main entry point
├── database.ts           # TypeORM configuration
├── entities/             # Database models
│   ├── User.ts
│   ├── Report.ts
│   ├── Case.ts
│   ├── Incentive.ts
│   └── USSDSession.ts
├── routes/               # API endpoints (to be created)
├── services/             # Business logic (to be created)
├── middleware/           # Auth, validation (to be created)
├── migrations/           # Database migrations
└── utils/                # Helpers (to be created)
```

## 🗄️ Database Schema

Core entities are defined in `src/entities/`:
- **User**: Citizens and authorities with roles
- **Report**: Immutable violation reports with metadata
- **Case**: Workflow state machine (submitted → approved → assigned → completed)
- **Incentive**: Points and rewards tracking
- **USSDSession**: USSD menu state management

## 🔑 Key Features (Implemented)

### Authentication ✅
- POST `/api/v1/auth/request-otp` - Request OTP via SMS (mobile citizens)
- POST `/api/v1/auth/verify-otp` - Verify OTP and get JWT token
- POST `/api/v1/auth/refresh` - Refresh access token
- POST `/api/v1/auth/login-dashboard` - Email + password login (authority staff)
- POST `/api/v1/auth/register-dashboard` - Register new admin/officer
- GET `/api/v1/auth/me` - Get current user info

### Reports ✅
- POST `/api/v1/reports` - Submit sanitation violation report
- GET `/api/v1/reports/{id}` - Get report status and incentive info
- GET `/api/v1/reports` - List user's reports with filters
- GET `/api/v1/reports/analytics/heatmap` - Get violations heatmap data

### Cases (Authority Workflow) ✅
- GET `/api/v1/cases` - List pending cases (admin only)
- GET `/api/v1/cases/{id}` - Get case details
- POST `/api/v1/cases/{id}/approve` - Approve and assign to officer (admin)
- POST `/api/v1/cases/{id}/reject` - Reject with reason (admin)
- POST `/api/v1/cases/{id}/complete` - Mark complete with evidence (officer)

### Features Not Yet Implemented
- USSD routes (to be added)
- File upload endpoints (photo/video)
- SMS integration (OTP sending)
- Notification system (email/SMS)

## 🧪 Testing

```bash
# Run all tests
npm test

# Watch mode
npm test:watch

# With coverage
npm test:coverage
```

## 🛠️ Development Commands

```bash
# Start dev server with auto-reload
npm run dev

# Build TypeScript
npm build

# Run linter
npm run lint

# Generate database migration
npm run migration:generate -- -n MigrationName

# Revert last migration
npm run migration:revert
```

## 🔐 Authentication Strategy

- **Mobile App**: JWT tokens (7-day expiry) with OTP registration
- **Authority Dashboard**: Email + password (Bcrypt) or SSO
- **USSD**: Phone number verification via carrier

## 📊 Data Integrity Principles

1. **Reports are immutable** - No edits after submission
2. **Complete metadata required** - GPS + timestamp mandatory
3. **Case status is directional** - No backward transitions
4. **Incentives tied to approval** - Points only awarded when case approved
5. **Audit trails** - All state changes logged with user + timestamp

## 🚨 Important Constraints

- Phone numbers stored with country code (+233...)
- Timestamps always ISO 8601, UTC
- Coordinates in WGS84 decimal degrees
- Report categories as string enums (not numeric)

---

**Phase**: Backend Foundation (Phase 1) ✅ COMPLETE
**Status**: Core auth, reports, and case workflows implemented. Ready for Phase 2 (Mobile App)
