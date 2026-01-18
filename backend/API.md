# Ghana Sanitation Platform - API Quick Reference

## 🔐 Authentication Endpoints

### Request OTP (Mobile Citizen Registration)
```
POST /api/v1/auth/request-otp
{
  "phone_number": "+233501234567"
}
Response: { "otp_expires_in": 300 }
```

### Verify OTP & Get Tokens
```
POST /api/v1/auth/verify-otp
{
  "phone_number": "+233501234567",
  "otp_code": "123456"
}
Response: {
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "user_id": "uuid",
  "expires_in": 604800
}
```

### Refresh Access Token
```
POST /api/v1/auth/refresh
{
  "refresh_token": "eyJ..."
}
Response: { "access_token": "...", "refresh_token": "...", "expires_in": 604800 }
```

### Dashboard Login (Admin/Officer)
```
POST /api/v1/auth/login-dashboard
{
  "email": "admin@example.com",
  "password": "SecurePassword123"
}
Response: { "access_token": "...", "refresh_token": "...", "user_id": "uuid" }
```

### Get Current User
```
GET /api/v1/auth/me
Authorization: Bearer {access_token}
Response: { "id": "uuid", "phone_number": "+233...", "role": "citizen", ... }
```

---

## 📋 Report Endpoints

### Submit Report
```
POST /api/v1/reports
Authorization: Bearer {access_token}
{
  "category": "plastic_dumping",
  "latitude": 5.6037,
  "longitude": -0.187,
  "gps_accuracy": 15,
  "captured_at": "2025-01-16T14:30:00Z",
  "description": "Plastic dumping near market",
  "anonymous": false
}
Response (201): { "report_id": "uuid", "case_id": "uuid", "status": "submitted" }
```

### Get Report Status
```
GET /api/v1/reports/{reportId}
Authorization: Bearer {access_token}
Response: {
  "id": "uuid",
  "category": "plastic_dumping",
  "status": "submitted",
  "case_status": "submitted",
  "points_earned": 0,
  "captured_at": "2025-01-16T14:30:00Z"
}
```

### List User Reports
```
GET /api/v1/reports?limit=20&offset=0&category=plastic_dumping&from_date=2025-01-01
Authorization: Bearer {access_token}
Response: {
  "total": 42,
  "limit": 20,
  "offset": 0,
  "reports": [...]
}
```

### Get Heatmap Data
```
GET /api/v1/reports/analytics/heatmap?min_lat=5.5&max_lat=5.7&min_lon=-0.3&max_lon=-0.1&category=plastic_dumping
Response: {
  "violations_by_location": [
    [5.6037, -0.187, 15],
    [5.6100, -0.150, 8],
    ...
  ]
}
```

---

## ⚖️ Case Endpoints (Authority Only)

### List Pending Cases
```
GET /api/v1/cases?status=submitted&limit=20&offset=0
Authorization: Bearer {admin_token}
Role: assembly_admin
Response: {
  "total": 128,
  "limit": 20,
  "offset": 0,
  "cases": [...]
}
```

### Get Case Details
```
GET /api/v1/cases/{caseId}
Authorization: Bearer {token}
Response: {
  "id": "uuid",
  "report_id": "uuid",
  "status": "submitted",
  "assigned_to": null,
  "approved_by": null,
  "created_at": "2025-01-16T14:30:00Z"
}
```

### Approve Case & Assign Officer
```
POST /api/v1/cases/{caseId}/approve
Authorization: Bearer {admin_token}
Role: assembly_admin
{
  "notes": "Verified violation",
  "assigned_to": "officer_uuid"
}
Response (200): {
  "status": "approved",
  "assigned_to": "officer_uuid",
  "approved_at": "2025-01-16T14:35:00Z",
  "officer_notified": true
}
```

### Reject Case
```
POST /api/v1/cases/{caseId}/reject
Authorization: Bearer {admin_token}
Role: assembly_admin
{
  "reason": "Insufficient evidence"
}
Response (200): {
  "status": "rejected",
  "approved_at": "2025-01-16T14:36:00Z",
  "user_notified": true
}
```

### Complete Case (Officer)
```
POST /api/v1/cases/{caseId}/complete
Authorization: Bearer {officer_token}
Role: enforcement_officer
{
  "completion_evidence_url": "https://s3.example.com/evidence.jpg"
}
Response (200): {
  "status": "completed",
  "completed_at": "2025-01-16T15:00:00Z"
}
```

---

## 📊 Categories

```
- plastic_dumping
- gutter_dumping
- open_defecation
- construction_waste
```

---

## 🔄 Case Status Flow

```
SUBMITTED → APPROVED → ASSIGNED → COMPLETED
         ↘ REJECTED (no rewards)
```

---

## 🎯 Roles & Permissions

| Role | Can Do |
|------|--------|
| **citizen** | Submit reports, view own reports, track status |
| **enforcement_officer** | View assigned cases, mark cases completed |
| **assembly_admin** | View all cases, approve/reject, assign officers |

---

## ⏱️ Timeouts & Limits

| Item | Value |
|------|-------|
| OTP Expiry | 5 minutes |
| Access Token | 7 days |
| Refresh Token | 30 days |
| Max API Limit | 100 records per page |
| Max File Size | 50MB |

---

## 🚨 Error Responses

### Bad Request (400)
```json
{ "error": "Invalid GPS coordinates" }
```

### Unauthorized (401)
```json
{ "error": "Invalid or expired token" }
```

### Forbidden (403)
```json
{ "error": "Access denied" }
```

### Not Found (404)
```json
{ "error": "Report with id xyz not found" }
```

### Conflict (409)
```json
{ "error": "User with this phone number already exists" }
```

### Server Error (500)
```json
{ "error": "Internal server error" }
```

---

## 🧪 Example Flow: Complete Case Workflow

```bash
# 1. Citizen requests OTP
curl -X POST http://localhost:3000/api/v1/auth/request-otp \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+233501234567"}'

# 2. Citizen verifies OTP and gets token
TOKEN=$(curl -X POST http://localhost:3000/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+233501234567",
    "otp_code": "123456"
  }' | jq -r '.access_token')

# 3. Citizen submits report
REPORT=$(curl -X POST http://localhost:3000/api/v1/reports \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "category": "plastic_dumping",
    "latitude": 5.6037,
    "longitude": -0.187,
    "gps_accuracy": 15,
    "captured_at": "2025-01-16T14:30:00Z",
    "description": "Plastic dumping near market"
  }' | jq -r '.report_id')

# 4. Admin approves case
ADMIN_TOKEN=$(curl -X POST http://localhost:3000/api/v1/auth/login-dashboard \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "SecurePassword123"
  }' | jq -r '.access_token')

curl -X POST http://localhost:3000/api/v1/cases/$REPORT/approve \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "notes": "Verified",
    "assigned_to": "officer_uuid"
  }'

# 5. Check report - points now awarded
curl -X GET http://localhost:3000/api/v1/reports/$REPORT \
  -H "Authorization: Bearer $TOKEN"
```
