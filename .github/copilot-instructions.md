# Ghana Sanitation Platform - AI Agent Instructions

## 🎯 Project Vision
A civic-tech platform enabling Ghanaian citizens to report sanitation violations (illegal dumping, gutter contamination, construction waste) and empower authorities to enforce compliance and create sanitation jobs.

## 🏗️ System Architecture

### Three User Channels
1. **Mobile App (Flutter/Android)** - Primary reporting interface with photo/video capture, GPS tagging, timestamp
2. **USSD Shortcode (*XXX#)** - Feature phone support with WhatsApp/SMS upload integration
3. **Authority Web Dashboard** - Evidence review, case assignment, enforcement tracking, analytics

### Core Data Flow
```
Citizen Report (Mobile/USSD) 
  → Backend Case Management 
  → Authority Dashboard Review 
  → Enforcement Assignment 
  → Completion Tracking
```

## 📋 Key Features by Module

### Mobile App (Citizen)
- **Photo/Video Capture**: Max 30-60 second videos, auto-compress before upload
- **Auto-Metadata**: GPS location + ISO timestamp (no manual input needed)
- **Categories**: Plastic dumping | Gutter dumping | Open defecation | Construction waste
- **Anonymous Reporting**: Optional user identity masking
- **Status Tracking**: Real-time case progress visibility
- **Incentive System**: Points awarded only for verified reports → rewards (mobile data, cash, utility credits)

### USSD Gateway
- Menu-driven experience for feature phones
- Report submission, WhatsApp upload link generation, status checking
- Integration point: Backend must expose status API for USSD queries

### Authority Dashboard
- Evidence review with photo/video gallery
- Case approval/rejection workflow
- Enforcement officer task assignment
- Analytics: heatmaps of violation hotspots, compliance metrics

## 🛠️ Architecture Principles

### Separation of Concerns
- **Mobile App**: UI, local caching, offline queue of reports
- **Backend**: Business logic, case workflows, permissions, incentive calculation
- **USSD Gateway**: Stateless menu handler, delegates to backend for logic

### Data Integrity
- All reports immutable after submission
- GPS + timestamp captured client-side (cannot be spoofed server-side validation)
- Evidence files checksummed to prevent tampering
- Reject reports without complete metadata

### Scalability Considerations
- Expect high mobile report volume during peak hours
- USSD must handle feature phone constraints (text-only, latency)
- Dashboard queries need pagination (analytics on potentially thousands of cases)
- Offline report queue in app with sync when connectivity restored

## 📋 Database Schema Essentials

### Core Entities
**Users** (Citizens & Authorities)
- `id` (UUID), `phone_number` (unique), `otp_token`, `otp_expires_at`, `anonymous` (bool), `created_at`, `updated_at`
- Role: `citizen`, `enforcement_officer`, `assembly_admin`

**Reports** (Immutable after creation)
- `id` (UUID/sortable), `user_id`, `category` (enum), `latitude`, `longitude`, `gps_accuracy`, `captured_at` (ISO 8601)
- `photo_urls` (array), `video_url`, `description`, `anonymous` (bool), `created_at`
- Indexes: `(latitude, longitude)` for heatmaps, `created_at` for timeline queries

**Cases** (Workflow state machine)
- `id` (UUID), `report_id`, `status` (submitted → approved → assigned → completed), `assigned_to` (officer_id)
- `approved_by` (admin_id), `approval_notes`, `approved_at`, `completed_at`, `completion_evidence_url`
- Audit trail: `status_history` (array of {status, changed_by, timestamp, reason})

**Incentives** (Points & Rewards)
- `id` (UUID), `user_id`, `report_id`, `points` (0 until case approved), `status` (pending → earned → redeemed)
- `reward_type` (data_bundle, cash_token, utility_credit), `redeem_date`, `audit_log`

**USSD Sessions** (Stateless but audited)
- `session_id`, `phone_number`, `menu_state`, `created_at`, `expires_at`
- Store report_id for upload token generation

### Key Constraints
- Reports: NO updates after submission (archive old version if correction needed)
- Cases: Status flow is directional (never go backward)
- Users: Phone number is globally unique, OTP expires in 5 minutes
- Incentives: Points awarded only when case.status = 'approved'

## 🔐 Security & Authentication Strategy

### Mobile App
- **Registration**: Phone number + OTP (SMS via Twilio/Nexmo)
- **Token**: JWT with 7-day expiry, refresh token with 30-day expiry
- **Report submission**: Must be authenticated; GPS + timestamp server-validated
- **Offline mode**: Queue reports locally, sync on reconnect with auth token

### USSD Gateway
- **Stateless**: Each request includes phone number (from carrier)
- **Authentication**: Phone number verification via carrier (no password needed)
- **Rate limiting**: Max 3 requests per phone per minute
- **Sensitive data**: Never return report details in USSD (only IDs and status summaries)

### Authority Dashboard
- **Authentication**: Email + password (Bcrypt hashing) or SSO via government directory
- **Role-based access**: admins see all cases; officers see assigned cases only
- **Audit logging**: All approvals, rejections, assignments logged with user + timestamp
- **File access**: Signed URLs for evidence files (10-minute expiry)

## 🚀 Initial Implementation Priority

### Phase 1: Backend Foundation (First)
1. Set up API server (Node.js/Express or Python/FastAPI)
2. Implement User model + phone OTP auth
3. Create Report model (immutable) + POST /api/v1/reports endpoint
4. Create Case model + workflow endpoints
5. Database migrations with audit trail

### Phase 2: Mobile App
1. Flutter project setup with Getx/Provider state management
2. Local SQLite db + Hive for offline queue
3. Camera + GPS integration (Geolocator, image_picker packages)
4. OTP login flow
5. Report submission with offline fallback

### Phase 3: USSD & Dashboard
1. USSD menu handler (Africa's Talking or Twilio)
2. React/Vue dashboard with case filtering & approval workflow
3. File upload & evidence gallery
4. Analytics: heatmap, case status breakdown

### Phase 4: Incentives & Rewards
1. Points calculation logic (verify before awarding)
2. Reward redemption interface
3. Leaderboard query (aggregate points by user)

## 🔑 Critical Integration Points

### Mobile-Backend API Contract
```
POST /api/v1/auth/request-otp
  Body: { phone_number: "+233xxxxxxxxx" }
  Response: { otp_expires_in: 300 }

POST /api/v1/auth/verify-otp
  Body: { phone_number, otp_code }
  Response: { access_token, refresh_token, user_id }

POST /api/v1/reports
  Headers: { Authorization: "Bearer {token}" }
  Body: multipart/form-data {
    category, latitude, longitude, gps_accuracy,
    captured_at (ISO 8601), photo (file), video (file),
    description, anonymous
  }
  Response: { report_id, case_id, status: "submitted" }

GET /api/v1/reports/{reportId}
  Response: { status, case_status, approval_status, points_earned }
```

### USSD-Backend API Contract
```
POST /api/v1/ussd/menu
  Body: { phone_number, session_id, user_input }
  Response: { menu_text, next_state, options: [{code, label}] }

GET /api/v1/report-status/{reportId}
  Params: phone_number (verification)
  Response: { status, approved_by, points, next_action }

POST /api/v1/ussd/upload-link
  Body: { phone_number, report_id }
  Response: { whatsapp_link, upload_token, expires_in: 3600 }
```

### Authority Dashboard-Backend API Contract
```
GET /api/v1/cases?status=submitted&limit=20&offset=0
  Response: { total_count, cases: [{id, report_id, submitted_at, ...}] }

POST /api/v1/cases/{caseId}/approve
  Body: { notes, assigned_to (officer_id) }
  Response: { status: "approved", officer_notified: true }

POST /api/v1/cases/{caseId}/reject
  Body: { reason }
  Response: { status: "rejected", user_notified: true }

GET /api/v1/analytics/heatmap?bounds={bbox}&zoom_level=10
  Response: { violations_by_location: [[lat, lon, count], ...] }
```

## 📂 Recommended Project Structure
```
/mobile          # Flutter app
/backend         # API server (Node/Python/Go)
/ussd-gateway    # USSD handler
/web-dashboard   # Authority dashboard (React/Vue)
/docs            # Architecture, API specs
```

## 🚀 Development Workflows

### Backend Setup (Node.js + PostgreSQL example)
```bash
# Initialize backend
cd backend
npm init -y
npm install express cors multer bcrypt jsonwebtoken dotenv pg typeorm

# Database migrations
npm run typeorm migration:generate -n InitialSchema
npm run typeorm migration:run

# Run tests
npm test -- --coverage

# Start dev server
npm run dev  # Should watch for changes
```

### Flutter Mobile Setup
```bash
# Initialize mobile app
flutter create --template=app mobile
cd mobile
flutter pub add geolocator image_picker provider sqflite hive http

# Run on emulator
flutter run -d emulator-5554

# Build APK
flutter build apk --release
```

### Testing Priorities
1. **Case workflow**: Submit → Approve → Assign → Complete (state machine tests)
2. **Incentive calculation**: Points only awarded when status = 'approved' (unit tests)
3. **Offline sync**: Queue reports locally, verify all sync on reconnect (integration tests)
4. **USSD menu**: Each option leads to valid next state (state machine tests)
5. **File upload**: Checksum verification, malware scanning (integration tests)

## 📝 Code Style & Patterns

### Naming & Data Formats
- **Timestamp**: Always ISO 8601, UTC timezone (e.g., `2025-01-16T14:30:00Z`)
- **Coordinates**: WGS84 decimal degrees (e.g., `5.6037, -0.1870` for Accra)
- **Phone numbers**: Always stored with country code (e.g., `+233XXXXXXXXX`)
- **Report IDs**: Use UUID v4 or ULID for sortability by time
- **Categories**: String enums, not numeric (e.g., `enum Category { PLASTIC_DUMPING, GUTTER_DUMPING, OPEN_DEFECATION, CONSTRUCTION_WASTE }`)

### Error Handling
- **GPS unavailable**: Return cached last-known location with accuracy=null and `gps_available: false` flag
- **Network offline**: Queue report locally, show "Will sync when online" message
- **USSD carrier issue**: Fall back to error message: "Service temporarily unavailable. Try again in 5 minutes."
- **File upload failure**: Return 409 with `error: "evidence_not_complete"` until all files present

### State Machines (Critical)
**Report Status**: `submitted` → `approved` | `rejected` (no reverse)
**Case Status**: `submitted` → `approved` → `assigned` → `completed` | (rejection at approval only)
**Incentive Status**: `pending` → `earned` → `redeemed` (no reverse)

### Logging
- Log all state transitions with user ID + timestamp
- Log all file uploads with checksum + size
- Log USSD menu navigation for debugging feature phone issues
- Avoid logging PII (phone numbers only in audit context)

### Testing Template
```javascript
// Example: Case approval test
describe('Case Workflow', () => {
  it('should award points when case approved', async () => {
    const report = await createReport(userId);
    const case = await createCase(report.id);
    await approveCase(case.id, adminId);
    const incentive = await getIncentive(userId, report.id);
    expect(incentive.points).toBeGreaterThan(0);
    expect(incentive.status).toBe('earned');
  });
});
```

---

**Last updated**: Jan 16, 2026  
**Current status**: Schema & API contracts defined. Ready for Phase 1 backend implementation.
