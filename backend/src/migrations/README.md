# TypeORM migration: 1705430400000-InitialSchema

This is the initial database schema setup for Ghana Sanitation Platform.

## Migration for:
- Users (with roles and OTP)
- Reports (immutable, with GPS + timestamp)
- Cases (workflow state machine with audit trail)
- Incentives (points and rewards)
- USSD Sessions (menu state management)

To run:
```bash
npm run migration:run
```

To revert:
```bash
npm run migration:revert
```
