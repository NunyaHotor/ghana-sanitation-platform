# 🚀 Next Steps: Phase 2 - Mobile App Development

## Backend is Complete ✅

The Ghana Sanitation Platform backend is production-ready with:
- 15 API endpoints
- 5 database entities
- Complete authentication system
- Case workflow state machine
- Incentive system with points

**Location**: `/home/mawutor/ghana-sanitation-platform/backend`

---

## What the Mobile App Needs to Know

### 1. Registration Flow
```
User enters phone number
  ↓
POST /api/v1/auth/request-otp { phone_number: "+233..." }
  ↓ (OTP sent via SMS)
User enters 6-digit OTP
  ↓
POST /api/v1/auth/verify-otp { phone_number, otp_code }
  ↓
Returns: { access_token, refresh_token, user_id, expires_in }
```

### 2. Report Submission
```
User captures photo/video and location
  ↓
POST /api/v1/reports
{
  "category": "plastic_dumping",
  "latitude": 5.6037,
  "longitude": -0.187,
  "gps_accuracy": 15,
  "captured_at": "2025-01-16T14:30:00Z",
  "description": "Plastic dumping near market",
  "anonymous": false
}
Authorization: Bearer {access_token}
  ↓
Returns: { report_id, case_id, status: "submitted" }
```

### 3. Status Tracking
```
User wants to check case progress
  ↓
GET /api/v1/reports/{reportId}
Authorization: Bearer {access_token}
  ↓
Returns: { status, case_status, points_earned, created_at }
```

---

## Offline Queue Implementation

The mobile app should:

1. **Local Storage**: Use SQLite + Hive to queue reports
2. **When Offline**: Store in local queue
3. **When Online**: Sync all pending reports
4. **Error Handling**: Retry with exponential backoff

Expected flow:
```
Report submitted (offline)
  ↓ (stored locally)
Network restored
  ↓
Sync queued reports
  ↓ (bulk upload with retries)
Update status in UI
```

---

## Important API Notes

### Headers Required
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

### Token Management
- Access token: 7 days
- Refresh token: 30 days
- Refresh when expired:
  ```
  POST /api/v1/auth/refresh
  { "refresh_token": "..." }
  ```

### Error Handling
```
401: Unauthorized → Need to re-authenticate
403: Forbidden → User doesn't have permission
400: Bad Request → Check GPS coords (lat: -90 to 90, lon: -180 to 180)
409: Conflict → User already exists
```

### GPS Validation
- Latitude: -90 to 90
- Longitude: -180 to 180
- Ghana bounds: lat 1.0-11.2, lon -3.3 to 1.2

### Timestamp Format
- Must be ISO 8601: `2025-01-16T14:30:00Z`
- Must not be in future
- Should be in UTC

---

## Backend Server Setup

Before mobile testing, ensure:

```bash
cd /home/mawutor/ghana-sanitation-platform/backend

# 1. Install dependencies
npm install

# 2. Create .env file
cp .env.example .env

# 3. Update .env with:
#    - DB_HOST, DB_USERNAME, DB_PASSWORD, DB_NAME
#    - JWT_SECRET (strong random value)
#    - SMS provider credentials (Twilio/Nexmo)

# 4. Run migrations
npm run migration:run

# 5. Start server
npm run dev
```

Server will run on: `http://localhost:3000`

---

## Testing the API

### Test OTP Flow
```bash
# Request OTP
curl -X POST http://localhost:3000/api/v1/auth/request-otp \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+233501234567"}'

# [In development] Check console for OTP code
# Then verify with OTP
curl -X POST http://localhost:3000/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+233501234567",
    "otp_code": "123456"
  }'
```

### Test Report Submission
```bash
# With token from above
TOKEN="eyJ..."

curl -X POST http://localhost:3000/api/v1/reports \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "category": "plastic_dumping",
    "latitude": 5.6037,
    "longitude": -0.187,
    "gps_accuracy": 15,
    "captured_at": "2025-01-16T14:30:00Z",
    "description": "Test report"
  }'
```

---

## Architecture to Follow

When building the mobile app:

1. **Keep Services Separate**
   - Authentication service
   - Report service
   - Offline queue service
   - Sync service

2. **State Management**
   - Use Provider or GetX (recommended in copilot-instructions)
   - Track auth state
   - Track pending reports

3. **Validation**
   - Validate GPS coordinates before submit
   - Validate timestamp format
   - Validate category selection

4. **Error Handling**
   - Catch network errors
   - Queue locally if offline
   - Show user-friendly messages

5. **Security**
   - Store tokens securely (FlutterSecureStorage)
   - Never expose JWT in logs
   - Validate URLs before opening

---

## Documentation References

For detailed API information, see:
- **API Reference**: `backend/API.md`
- **Setup Guide**: `backend/README.md`
- **Architecture**: `.github/copilot-instructions.md`

---

## Example: Complete User Journey

```
1. App launches
   └─ Check if token exists, refresh if needed

2. User not authenticated
   └─ Open login screen
      └─ User enters phone number
         └─ POST /api/v1/auth/request-otp
            └─ User sees "OTP sent" message

3. User enters OTP
   └─ POST /api/v1/auth/verify-otp
      └─ Receive access_token + refresh_token
         └─ Store securely
            └─ Navigate to report screen

4. User captures incident
   └─ Take photo/video
   └─ Auto-capture GPS + timestamp
      └─ Select category
         └─ Add description (optional)
            └─ Choose: anonymous or identified

5. User submits report
   └─ If online:
      └─ POST /api/v1/reports (with token)
         └─ Receive report_id
            └─ Navigate to tracking screen
   └─ If offline:
      └─ Queue locally
         └─ Show "Will sync when online"
            └─ When online: sync & update

6. User tracks case
   └─ GET /api/v1/reports/{reportId}
      └─ Show status: submitted → approved → completed
         └─ Show points earned when approved

7. User redeems rewards
   └─ [In Phase 4] Redeem points
      └─ Select reward (data/cash/utility)
         └─ Confirm & complete
```

---

## Ready for Flutter Development 🚀

The backend is complete and documented. Mobile team can:

1. ✅ Read API.md for endpoint specifications
2. ✅ Set up test backend locally
3. ✅ Start Flutter project scaffolding
4. ✅ Implement auth flow (OTP)
5. ✅ Implement report submission
6. ✅ Add offline queue
7. ✅ Implement status tracking

All backend integration points are documented and ready!

---

## Questions?

Refer to:
- **API Contract**: `backend/API.md`
- **Code Examples**: `backend/src/routes/` and `backend/src/services/`
- **Architecture**: `.github/copilot-instructions.md`

---

**Status**: Backend ✅ | Mobile App Ready to Start 🚀
