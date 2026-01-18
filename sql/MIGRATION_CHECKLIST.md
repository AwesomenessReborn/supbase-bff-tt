# Migration Execution Checklist

Use this checklist when running database migrations for the Rush App.

## Pre-Migration Setup

- [ ] Supabase project created
- [ ] Supabase credentials added to `.env` file
- [ ] Database URL copied from Supabase project settings
- [ ] Logged into Supabase dashboard

## Run Migrations in Order

Execute each migration in the Supabase SQL Editor:

### ✅ Migration 001 - Users Table

- [x] Already exists
- [x] Creates: `users` table with RLS
- [x] Creates: `update_updated_at_column()` trigger function

### Migration 002 - Events Table

- [ ] File: `sql/migrations/002_create_events_table.sql`
- [ ] Creates: `events` table with RLS policies
- [ ] Indexes: start_time, event_type, created_by

**Verification:**

```sql
SELECT COUNT(*) FROM events; -- Should return 0
```

---

### Migration 003 - Attendance Table

- [ ] File: `sql/migrations/003_create_attendance_table.sql`
- [ ] Creates: `attendance` table with RSVP support
- [ ] Constraint: Unique(event_id, user_id)

**Verification:**

```sql
SELECT COUNT(*) FROM attendance; -- Should return 0
```

---

### Migration 004 - Votes Table

- [ ] File: `sql/migrations/004_create_votes_table.sql`
- [ ] Creates: `votes` table with anonymity support
- [ ] Constraint: Unique(voter_id, candidate_id, voting_round)

**Verification:**

```sql
SELECT COUNT(*) FROM votes; -- Should return 0
```

---

### Migration 005 - Feedback Table

- [ ] File: `sql/migrations/005_create_feedback_table.sql`
- [ ] Creates: `feedback` table with tags and ratings
- [ ] Supports: Anonymous and private feedback

**Verification:**

```sql
SELECT COUNT(*) FROM feedback; -- Should return 0
```

---

### Migration 006 - Dues Payments Table

- [ ] File: `sql/migrations/006_create_dues_payments_table.sql`
- [ ] Creates: `dues_payments` table
- [ ] Status options: PAID, PARTIAL, NOT_PAID, OVERDUE, WAIVED

**Verification:**

```sql
SELECT COUNT(*) FROM dues_payments; -- Should return 0
```

---

### Migration 007 - Interviews Table

- [ ] File: `sql/migrations/007_create_interviews_table.sql`
- [ ] Creates: `interviews` table with JSONB Q&A support
- [ ] Fields: questions_and_answers, strengths, concerns

**Verification:**

```sql
SELECT COUNT(*) FROM interviews; -- Should return 0
```

---

### Migration 008 - Candidate Stage Tracking

- [ ] File: `sql/migrations/008_add_candidate_stage_to_users.sql`
- [ ] Adds: `candidate_stage` column to users table
- [ ] Index: idx_users_candidate_stage

**Verification:**

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'candidate_stage';
-- Should return: candidate_stage | text
```

---

## Post-Migration Verification

### Check All Tables Created

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

**Expected output:**

- attendance
- dues_payments
- events
- feedback
- interviews
- users
- votes

### Check RLS Enabled on All Tables

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

**Expected output:**

All tables should have `rowsecurity = true`

### Check Indexes Created

```sql
SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

**Expected output:**

20+ indexes across all tables (including primary keys and custom indexes)

### Check Triggers

```sql
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table;
```

**Expected output:**

- update_attendance_updated_at
- update_dues_payments_updated_at
- update_events_updated_at
- update_feedback_updated_at
- update_interviews_updated_at
- update_users_updated_at
- update_votes_updated_at

---

## Update Local Development Environment

After running all migrations:

### 1. Install Prisma (if not already)

```bash
cd /Users/hareee234/Dev/projects/tt/bff
pnpm add @prisma/client
pnpm add -D prisma
```

### 2. Add DATABASE_URL to .env

```bash
# Add to .env file
DATABASE_URL="postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"
```

### 3. Pull Schema from Supabase

```bash
npx prisma db pull
```

**This will update:** `prisma/schema.prisma`

### 4. Generate Prisma Client

```bash
npx prisma generate
```

**This will create:** Type-safe Prisma Client in `node_modules/@prisma/client`

### 5. Verify TypeScript Types

```bash
# Create a test file to verify types
cat > test-types.ts << 'EOF'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function test() {
  // Should have autocomplete for all tables
  const users = await prisma.users.findMany()
  const events = await prisma.events.findMany()
  const attendance = await prisma.attendance.findMany()
  const votes = await prisma.votes.findMany()
  const feedback = await prisma.feedback.findMany()
  const dues = await prisma.dues_payments.findMany()
  const interviews = await prisma.interviews.findMany()
}
EOF

# Try to compile (should have no errors)
npx tsc --noEmit test-types.ts
rm test-types.ts
```

---

## Install Additional Dependencies

```bash
# Supabase client for auth and RLS
pnpm add @supabase/supabase-js

# Testing framework
pnpm add -D jest @types/jest ts-jest supertest @types/supertest

# Additional utilities
pnpm add zod  # For request validation
```

---

## Next Steps After Migrations

- [ ] Update `src/config/supabase.ts` to initialize Supabase client
- [ ] Create auth middleware in `src/middleware/auth.ts`
- [ ] Start building Events API routes (`src/routes/events.ts`)
- [ ] Create service layer for events (`src/services/events/`)
- [ ] Set up Jest for testing
- [ ] Build remaining features (attendance, votes, feedback, dues, interviews)

---

## Troubleshooting

### Error: "relation does not exist"

- **Cause:** Migration not run or run out of order
- **Solution:** Run migrations in exact order (001 → 008)

### Error: "function update_updated_at_column() does not exist"

- **Cause:** Migration 001 not run successfully
- **Solution:** Re-run migration 001

### Error: "permission denied for table"

- **Cause:** RLS policies blocking access
- **Solution:** Ensure you have a user record with proper role in users table

### Prisma pull fails

- **Cause:** DATABASE_URL not set or incorrect
- **Solution:** Verify DATABASE_URL in .env matches Supabase connection string

---

## Success Criteria

✅ All 8 migrations run without errors
✅ All tables visible in Supabase Table Editor
✅ RLS enabled on all tables
✅ Prisma schema pulled successfully
✅ Prisma Client generated with types
✅ TypeScript autocomplete working for all tables

**When all checkboxes are complete, you're ready to start building features!**
