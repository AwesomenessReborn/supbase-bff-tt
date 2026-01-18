# Database Migrations

This directory contains SQL migration files for the Rush App database schema.

## Migration Files

| File | Description | Dependencies |
|------|-------------|--------------|
| `001_create_users_table.sql` | ✅ User profiles linked to Supabase Auth | None |
| `002_create_events_table.sql` | Rush events (dinners, smokers, interviews) | users |
| `003_create_attendance_table.sql` | Event attendance tracking with RSVP support | users, events |
| `004_create_votes_table.sql` | Secret ballot voting on candidates | users, events |
| `005_create_feedback_table.sql` | Member feedback and ratings on candidates | users, events |
| `006_create_dues_payments_table.sql` | Financial dues and payment tracking | users |
| `007_create_interviews_table.sql` | Interview content and assessments | users, events |
| `008_add_candidate_stage_to_users.sql` | Adds candidate progression tracking to users | users |

## How to Run Migrations

### Option 1: Supabase SQL Editor (Recommended)

1. Log into your Supabase project dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy the contents of each migration file **in order** (001 → 008)
5. Paste into the editor and click **Run**
6. Verify success before proceeding to the next migration

### Option 2: Supabase CLI

```bash
# Install Supabase CLI if not already installed
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push
```

### Option 3: Direct PostgreSQL Connection

```bash
# Using psql (if you have direct database credentials)
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  -f sql/migrations/001_create_users_table.sql

# Repeat for each migration file in order
```

## Verification

After running all migrations, verify the schema:

```sql
-- Check all tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Expected tables:
-- - users
-- - events
-- - attendance
-- - votes
-- - feedback
-- - dues_payments
-- - interviews

-- Verify RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
-- All tables should have rowsecurity = true
```

## Next Steps After Running Migrations

1. **Update Prisma Schema**
   ```bash
   npx prisma db pull
   ```

2. **Generate Prisma Client**
   ```bash
   npx prisma generate
   ```

3. **Verify TypeScript Types**
   - Check `node_modules/@prisma/client/index.d.ts`
   - You should see types for all tables and relationships

4. **Start Building Features**
   - Begin with Events + Attendance
   - Then Votes and Feedback
   - Finally Dues and Interviews

## Migration Order Explanation

The migrations must be run in order due to foreign key dependencies:

```
001: users (foundation)
     ├── 002: events (references users.created_by)
     │    ├── 003: attendance (references users + events)
     │    ├── 004: votes (references users + events)
     │    ├── 005: feedback (references users + events)
     │    └── 007: interviews (references users + events)
     ├── 006: dues_payments (references users only)
     └── 008: alter users (adds candidate_stage column)
```

## Rollback (If Needed)

To rollback a migration, you'll need to manually drop tables in reverse order:

```sql
-- Drop in reverse order to respect foreign key constraints
DROP TABLE IF EXISTS interviews CASCADE;
DROP TABLE IF EXISTS feedback CASCADE;
DROP TABLE IF EXISTS votes CASCADE;
DROP TABLE IF EXISTS attendance CASCADE;
DROP TABLE IF EXISTS dues_payments CASCADE;
DROP TABLE IF EXISTS events CASCADE;

-- Optionally drop users table (be careful!)
-- DROP TABLE IF EXISTS users CASCADE;
```

⚠️ **Warning:** Dropping tables will delete all data. Only do this in development.

## RLS Policies Summary

Each table has Row Level Security policies that enforce:

- **Users can view their own data** (attendance, votes, feedback, dues, interviews)
- **Admins can view/manage all data**
- **Active members can view aggregated data** (candidate feedback, interview summaries)
- **Vote anonymity is enforced** (only admins see individual votes, others see counts)
- **Private feedback is restricted** to authors and admins

## Common Issues

### Issue: Foreign key constraint violation
**Solution:** Ensure migrations are run in order (001 → 008)

### Issue: RLS preventing access
**Solution:** Ensure your Supabase user has proper role in users table matching auth.uid()

### Issue: Trigger function not found
**Solution:** Ensure migration 001 ran successfully (it creates `update_updated_at_column()`)

## Schema Modifications

If you need to modify the schema later:

1. Create a new migration file with sequential numbering (e.g., `009_add_xyz_column.sql`)
2. Use `ALTER TABLE` statements instead of `CREATE TABLE`
3. Update Prisma schema with `npx prisma db pull`
4. Regenerate client with `npx prisma generate`

## Contact

For questions about the schema design, see `/docs/database-schema.md`
