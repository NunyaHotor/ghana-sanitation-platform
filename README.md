# ghana-sanitation-platform
Digital sanitation, reporting and enforcement system for Ghana
# Ghana Sanitation Reporting & Enforcement Platform

A civic-tech platform for **reporting sanitation offenses**, enabling **lawful enforcement**, and creating **sanitation employment** across Ghana.

This project includes:
- A mobile reporting app (Android / Flutter)
- A USSD shortcode for feature phones
- A backend for case management
- An authority dashboard for Assemblies
- Support for courts and enforcement officers


## 🌍 Problem

Illegal dumping of waste, especially plastics and construction debris, harms public health, blocks drains, and increases flooding risk in Ghanaian cities. Local authorities lack scalable tools to monitor and enforce sanitation laws at community level.


## 💡 Solution

The Ghana Sanitation Reporting & Enforcement Platform empowers citizens to:
- Report sanitation violations via smartphone or USSD
- Upload photo/video evidence with GPS and timestamp
- Track case progress
- Enable authorities to enforce penalties
- Assign community service tasks
- Create sanitation job opportunities


## 🚀 Project Status

### ✅ Phase 1: Backend Foundation - COMPLETE
- Express.js/Node.js REST API with TypeORM
- PostgreSQL database with 5 core entities
- Authentication: OTP (mobile) + email/password (dashboard)
- Report management with immutability
- Case workflow state machine with audit trail
- Incentive system (points for verified reports)
- 15 API endpoints, fully tested

**See**: `backend/README.md`, `backend/API.md`, `backend/IMPLEMENTATION.md`

### 🚀 Phase 2: Mobile App - IN PROGRESS
- Flutter Android/iOS app
- Hive local database + offline queue
- GPS + camera integration
- OTP login (SMS verification)
- Real-time case tracking
- Offline-first architecture
- Auto-sync when online

**See**: `mobile/README.md`

**See**: `mobile/README.md` (coming soon)

### ⏳ Phase 3: Authority Dashboard & USSD - PENDING
- React/Vue dashboard for case review
- USSD menu handler (Africa's Talking)
- Analytics & heatmap visualization
- File upload & evidence gallery

## 🧠 Key Features

### 📱 Mobile App
- Real-time photo/video upload
- Auto-capture GPS & timestamp
- Case tracking
- Anonymous or identified reporting

### 📡 USSD Menu
- Feature-phone support (*XXX#)
- Report sanitation offense
- Get WhatsApp upload link
- Check case status

### 🛠 Authority Dashboard
- Evidence review
- Case assignment
- Enforcement tracking
- Analytics & heatmaps

### 🪪 Sanitation Worker Portal
- Task assignment
- Job scheduling
- Completion reporting
- Payment tracking


## 🏗️ Architecture

```
Citizen Report (Mobile/USSD)
    ↓
Backend Case Management
    ↓
Authority Dashboard Review
    ↓
Enforcement Officer Assignment
    ↓
Completion Tracking & Incentives
```

### Three User Channels
1. **Mobile App (Flutter)** - Android reporting with GPS + photo/video
2. **USSD Shortcode (*XXX#)** - Feature phone support
3. **Web Dashboard** - Authority staff (admins + enforcement officers)

---

## 📂 Quick Start

### Backend Development
```bash
cd backend
npm install
cp .env.example .env
npm run migration:run
npm run dev
```

See `backend/README.md` for detailed instructions.

### API Documentation
See `backend/API.md` for complete endpoint reference and examples.

### Architecture Guide
See `.github/copilot-instructions.md` for system design and patterns.

---

## 🔑 Key Implementation Details

### Authentication
- **Citizens**: OTP via SMS (7-day JWT tokens)
- **Dashboard Users**: Email + password (Bcrypt, 30-day refresh tokens)
- **Role-based access**: citizen, enforcement_officer, assembly_admin

### Reports
- **Immutable** after creation (no edits)
- **Complete metadata** required (GPS + ISO 8601 timestamp)
- **Categories**: plastic dumping, gutter dumping, open defecation, construction waste
- **Anonymous option** available

### Case Workflow
```
SUBMITTED → APPROVED → ASSIGNED → COMPLETED
         ↘ REJECTED (no points)
```

All state changes logged with user ID + timestamp (audit trail).

### Incentives
- **10 points** per verified report (on approval)
- **Status**: pending → earned → redeemed
- **Rewards**: mobile data, cash tokens, utility credits
- **No rewards** for rejected reports

---

## 📊 Database Schema

5 core entities in PostgreSQL:
1. **Users** - Citizens & authority staff (with roles)
2. **Reports** - Immutable violation reports
3. **Cases** - Workflow state machine with audit trail
4. **Incentives** - Points & reward tracking
5. **USSDSessions** - Feature phone menu state

See `backend/src/entities/` for complete definitions.

---

## 🧪 Testing

```bash
cd backend
npm test                # Run all tests
npm test:coverage      # Coverage report
```

Example integration test: `backend/src/__tests__/case-workflow.test.ts`

---

## 📋 Documentation

| Document | Purpose |
|----------|---------|
| `backend/README.md` | Backend setup & features |
| `backend/API.md` | Complete API reference |
| `backend/IMPLEMENTATION.md` | Implementation summary |
| `.github/copilot-instructions.md` | Architecture & patterns |
| `PROJECT_STRUCTURE.md` | File organization |

---

## 🤝 Contributing

When implementing new features, reference:
1. **Copilot Instructions** - System architecture and patterns
2. **API Contract** - Expected request/response formats
3. **Database Schema** - Entity relationships and constraints
4. **Case Workflow** - State machine integrity

---

## 📝 License

MIT - See LICENSE file

---

## 👥 Team

Ghana Sanitation Platform - Civic Tech Initiative

**Current Phase**: Backend Complete ✅ | Mobile App Next 🚀




