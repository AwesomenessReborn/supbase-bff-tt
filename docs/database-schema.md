# Database Schema Design - Rush App

**Last Updated:** 2026-01-18
**Status:** ✅ Migrations Created - Ready to Apply

---

## Overview

This document outlines the complete database schema for the Rush App backend. All tables use UUID primary keys, include audit timestamps, and have RLS (Row Level Security) enabled.

### Design Principles

1. **Audit Trail** - All tables have `created_at` and `updated_at` timestamps
2. **Soft Deletes** - Use `is_active`/`is_deleted` flags instead of hard deletes where appropriate
3. **UUID Keys** - Use UUIDs for all primary keys for security and distributed systems
4. **Indexed Lookups** - Foreign keys and frequently queried columns are indexed
5. **Referential Integrity** - Foreign keys with CASCADE deletes where appropriate
6. **Flexible Enums** - Use TEXT with CHECK constraints instead of PostgreSQL ENUMs for easier migrations

---

## Tables

### 1. `users` ✅ (Already Implemented)

**Purpose:** Application user profiles linked to Supabase Auth

```sql
users (
  id UUID PRIMARY KEY,
  supabase_id UUID UNIQUE NOT NULL,  -- Links to auth.users(id)
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL,                -- 'ADMIN' | 'ACTIVE' | 'PLEDGE' | 'RUSHEE'
  candidate_stage TEXT,              -- Tracks RUSHEE progression (added in migration 008)
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
```

**Relationships:**

- One-to-one with `auth.users` (Supabase Auth)
- One-to-many with `attendance`, `votes`, `feedback`, `dues_payments`, `interviews`

**Indexes:**

- `idx_users_supabase_id` on `supabase_id`
- `idx_users_email` on `email`
- `idx_users_candidate_stage` on `candidate_stage`

**Notes:**

- RUSHEE = candidate being rushed
- PLEDGE = accepted, not yet initiated
- ACTIVE = full voting member
- ADMIN = rush chair or admin

---

### 2. `events`

**Purpose:** Rush events (dinners, smokers, interviews, etc.)

```sql
events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Event Details
  title TEXT NOT NULL,                    -- "Fall Smoker", "Steak Dinner", "Interview Night"
  description TEXT,                       -- Full description of the event
  event_type TEXT NOT NULL,               -- 'DINNER' | 'SMOKER' | 'INTERVIEW' | 'SOCIAL' | 'MEETING' | 'OTHER'

  -- Scheduling
  start_time TIMESTAMPTZ NOT NULL,        -- When event starts
  end_time TIMESTAMPTZ,                   -- When event ends (optional)
  location TEXT,                          -- "Chapter House", "Downtown Restaurant"

  -- Rush-Specific
  is_mandatory BOOLEAN DEFAULT false,     -- Required for actives to attend
  is_voting_event BOOLEAN DEFAULT false,  -- Whether voting happens at/after this event
  max_capacity INTEGER,                   -- Max attendees (optional)

  -- Metadata
  created_by UUID REFERENCES users(id),   -- Who created the event
  is_active BOOLEAN DEFAULT true,         -- Soft delete flag
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
)
```

**Relationships:**

- Many-to-one with `users` (creator)
- One-to-many with `attendance`, `feedback`, `votes`

**Indexes:**

- `idx_events_start_time` on `start_time` (for chronological queries)
- `idx_events_event_type` on `event_type`
- `idx_events_created_by` on `created_by`

**Business Rules:**

- `start_time` must be in the future when created (app validation)
- `end_time` must be after `start_time` if provided

---

### 3. `attendance`

**Purpose:** Track who attended which events

```sql
attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Attendance Details
  status TEXT NOT NULL DEFAULT 'PENDING',  -- 'PENDING' | 'PRESENT' | 'ABSENT' | 'EXCUSED' | 'LATE'
  checked_in_at TIMESTAMPTZ,               -- When they actually checked in
  checked_in_by UUID REFERENCES users(id), -- Who marked them present (admin/rush chair)

  -- Notes
  notes TEXT,                              -- "Arrived 30min late", "Left early for class"

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  -- Prevent duplicate attendance records
  UNIQUE(event_id, user_id)
)
```

**Relationships:**

- Many-to-one with `events`
- Many-to-one with `users` (attendee)
- Many-to-one with `users` (checker)

**Indexes:**

- `idx_attendance_event_id` on `event_id`
- `idx_attendance_user_id` on `user_id`
- `idx_attendance_status` on `status`

**Business Rules:**

- A user can only have one attendance record per event (UNIQUE constraint)
- `checked_in_at` required when `status = 'PRESENT'`

---

### 4. `votes`

**Purpose:** Track voting on candidates (secret ballot)

```sql
votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,  -- Event where vote occurred (optional)
  voter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,      -- Who voted
  candidate_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,  -- Who they voted on

  -- Vote Details
  vote_type TEXT NOT NULL,                 -- 'BID' | 'NO_BID' | 'ABSTAIN'
  vote_value INTEGER,                      -- Optional: 1-10 rating scale

  -- Anonymity
  is_anonymous BOOLEAN DEFAULT true,       -- Whether vote is anonymous in reports

  -- Context
  voting_round TEXT,                       -- "Round 1", "Round 2", "Final" (optional)
  notes TEXT,                              -- Private notes (only visible to voter)

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  -- Prevent duplicate votes in same round
  UNIQUE(voter_id, candidate_id, voting_round)
)
```

**Relationships:**

- Many-to-one with `events` (optional)
- Many-to-one with `users` (voter)
- Many-to-one with `users` (candidate)

**Indexes:**

- `idx_votes_voter_id` on `voter_id`
- `idx_votes_candidate_id` on `candidate_id`
- `idx_votes_event_id` on `event_id`
- `idx_votes_vote_type` on `vote_type`

**Business Rules:**

- Only users with role 'ACTIVE' can vote (app validation)
- Candidate must have role 'RUSHEE' (app validation)
- A voter can only vote once per candidate per round

**Security:**

- RLS policies prevent users from seeing others' individual votes
- Aggregated results only (count, percentage)

---

### 5. `feedback`

**Purpose:** Written feedback on candidates from members

```sql
feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  event_id UUID REFERENCES events(id) ON DELETE SET NULL,  -- Event context (optional)
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  candidate_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Feedback Content
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),  -- 1-5 star rating
  comment TEXT,                                         -- Written feedback

  -- Categories (optional tags)
  tags TEXT[],                              -- ['good_fit', 'leadership', 'academic', 'social']

  -- Visibility
  is_anonymous BOOLEAN DEFAULT false,       -- Whether author name is hidden
  is_private BOOLEAN DEFAULT false,         -- Only visible to admins

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
)
```

**Relationships:**

- Many-to-one with `events` (optional context)
- Many-to-one with `users` (author)
- Many-to-one with `users` (candidate)

**Indexes:**

- `idx_feedback_author_id` on `author_id`
- `idx_feedback_candidate_id` on `candidate_id`
- `idx_feedback_event_id` on `event_id`
- `idx_feedback_rating` on `rating`

**Business Rules:**

- Only ACTIVE or PLEDGE members can submit feedback (app validation)
- Candidate must be RUSHEE (app validation)

---

### 6. `dues_payments`

**Purpose:** Track dues payments from members

```sql
dues_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Payment Details
  amount DECIMAL(10, 2) NOT NULL,           -- Amount in dollars (e.g., 150.00)
  payment_type TEXT NOT NULL,               -- 'INITIATION' | 'SEMESTER' | 'SOCIAL' | 'FINE' | 'OTHER'
  payment_method TEXT,                      -- 'CASH' | 'VENMO' | 'CHECK' | 'ZELLE' | 'OTHER'

  -- Status
  status TEXT NOT NULL DEFAULT 'NOT_PAID',   -- 'PAID' | 'PARTIAL' | 'NOT_PAID' | 'OVERDUE' | 'WAIVED'

  -- Dates
  due_date DATE NOT NULL,                   -- When payment is due
  paid_at TIMESTAMPTZ,                      -- When payment was received

  -- Financial Tracking
  semester TEXT,                            -- "Fall 2024", "Spring 2025"
  reference_number TEXT,                    -- Check number, Venmo ID, etc.

  -- Notes
  notes TEXT,                               -- "Late fee applied", "Payment plan approved"

  -- Admin Actions
  recorded_by UUID REFERENCES users(id),    -- Admin who recorded payment

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
)
```

**Relationships:**

- Many-to-one with `users` (payer)
- Many-to-one with `users` (recorder)

**Indexes:**

- `idx_dues_user_id` on `user_id`
- `idx_dues_status` on `status`
- `idx_dues_due_date` on `due_date`
- `idx_dues_semester` on `semester`

**Business Rules:**

- Amount must be positive (CHECK constraint)
- `paid_at` required when `status = 'PAID'`

---

### 7. `interviews`

**Purpose:** Capture interview content and assessments for candidates

```sql
interviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  event_id UUID REFERENCES events(id) ON DELETE SET NULL,  -- Optional: if interview happened at an event
  interviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  candidate_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Interview Details
  interview_date TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Interview Content (flexible structure)
  questions_and_answers JSONB,  -- Structured Q&A: [{"question": "...", "answer": "..."}, ...]
  notes TEXT,                    -- Free-form notes from interviewer

  -- Assessment
  overall_rating INTEGER CHECK (overall_rating >= 1 AND overall_rating <= 5),
  recommendation TEXT,           -- 'STRONG_BID' | 'BID' | 'NEUTRAL' | 'NO_BID' | 'STRONG_NO_BID'

  -- Key Attributes
  strengths TEXT[],              -- ['leadership', 'social', 'academic', etc.]
  concerns TEXT[],               -- ['time_commitment', 'fit', etc.]

  -- Status
  is_complete BOOLEAN DEFAULT true,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
)
```

**Relationships:**

- Many-to-one with `events` (optional context)
- Many-to-one with `users` (interviewer)
- Many-to-one with `users` (candidate)

**Indexes:**

- `idx_interviews_interviewer_id` on `interviewer_id`
- `idx_interviews_candidate_id` on `candidate_id`
- `idx_interviews_event_id` on `event_id`
- `idx_interviews_interview_date` on `interview_date`
- `idx_interviews_recommendation` on `recommendation`
- `idx_interviews_overall_rating` on `overall_rating`

**Business Rules:**

- Only ACTIVE members can conduct interviews (app validation)
- Candidate must be RUSHEE (app validation)
- JSONB field allows flexible interview questions structure

**Use Cases:**

- Display all interviews for a candidate profile
- Show interviewer's interview history
- Aggregate recommendation statistics
- Filter candidates by interview ratings

---

### 8. `notifications` (Optional - Future Phase)

**Purpose:** Track system notifications sent to users

```sql
notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Notification Content
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  notification_type TEXT NOT NULL,          -- 'EVENT_REMINDER' | 'VOTE_REMINDER' | 'PAYMENT_DUE' | 'ANNOUNCEMENT'

  -- Delivery
  delivery_method TEXT NOT NULL,            -- 'PUSH' | 'EMAIL' | 'SMS' | 'IN_APP'
  status TEXT DEFAULT 'PENDING',            -- 'PENDING' | 'SENT' | 'FAILED' | 'READ'

  -- Links
  action_url TEXT,                          -- Deep link to relevant screen
  related_entity_type TEXT,                 -- 'event' | 'vote' | 'payment'
  related_entity_id UUID,                   -- ID of the related entity

  -- Timestamps
  sent_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
)
```

**Relationships:**

- Many-to-one with `users`

**Indexes:**

- `idx_notifications_user_id` on `user_id`
- `idx_notifications_status` on `status`
- `idx_notifications_created_at` on `created_at`

---

## Entity Relationship Diagram (ERD)

```txt
┌─────────────┐
│   users     │──┐
│             │  │
│ - id        │  │
│ - email     │  │
│ - role      │  │
│ - stage     │  │
└─────────────┘  │
       │         │
       │ creates │
       ▼         │
┌─────────────┐  │
│   events    │  │
│             │  │
│ - id        │  │
│ - title     │  │
│ - type      │  │
│ - datetime  │  │
└─────────────┘  │
       │         │
       │         │
       ├─────────┴──────────┬──────────────┬────────────┬──────────────┐
       │                    │              │            │              │
       │ has many           │ has many     │            │ has many     │ has many
       ▼                    ▼              ▼            ▼              ▼
┌──────────────┐   ┌──────────────┐  ┌──────────┐  ┌──────────────┐  ┌──────────────┐
│  attendance  │   │    votes     │  │ feedback │  │dues_payments │  │  interviews  │
│              │   │              │  │          │  │              │  │              │
│ - event_id   │   │ - event_id   │  │- author  │  │ - user_id    │  │- interviewer │
│ - user_id    │   │ - voter_id   │  │- candidate│ │ - amount     │  │- candidate   │
│ - status     │   │ - candidate  │  │- rating  │  │ - status     │  │- rating      │
│ - rsvp       │   │ - vote_type  │  │- comment │  │ - due_date   │  │- notes       │
└──────────────┘   └──────────────┘  └──────────┘  └──────────────┘  └──────────────┘
```

---

## Summary Table

| Table | Primary Use | Key Relationships | Critical Indexes |
|-------|-------------|-------------------|------------------|
| `users` | User profiles & auth | → attendance, votes, feedback, dues, interviews | supabase_id, email, candidate_stage |
| `events` | Rush events | → attendance, votes, feedback, interviews | start_time, event_type |
| `attendance` | Track attendance | users, events | event_id, user_id, status |
| `votes` | Secret ballot voting | users (voter, candidate), events | candidate_id, voter_id |
| `feedback` | Member feedback | users (author, candidate), events | candidate_id, rating |
| `dues_payments` | Financial tracking | users | user_id, status, due_date |
| `interviews` | Interview assessments | users (interviewer, candidate), events | candidate_id, interviewer_id, recommendation |
| `notifications` | System alerts (future) | users | user_id, status |

---

## Migration Strategy

### Migration Order (Dependencies First)

1. ✅ `001_create_users_table.sql` - User profiles and auth
2. ✅ `002_create_events_table.sql` - Rush events
3. ✅ `003_create_attendance_table.sql` - Depends on: users, events
4. ✅ `004_create_votes_table.sql` - Depends on: users, events
5. ✅ `005_create_feedback_table.sql` - Depends on: users, events
6. ✅ `006_create_dues_payments_table.sql` - Depends on: users
7. ✅ `007_create_interviews_table.sql` - Depends on: users, events
8. ✅ `008_add_candidate_stage_to_users.sql` - Adds candidate progression tracking
9. `009_create_notifications_table.sql` - (Future) Depends on: users

### Shared Patterns

Each migration will include:

- Table creation with constraints
- Indexes for performance
- `update_updated_at_column()` trigger (already exists from 001)
- RLS enablement
- Example RLS policies (to be refined per feature)

---

## Next Steps

1. ✅ Schema design reviewed and finalized
2. ✅ Migration files created (002-008) in `sql/migrations/`
3. **→ Apply migrations to Supabase** (Run in SQL Editor)
4. Update `prisma/schema.prisma` with `npx prisma db pull`
5. Generate Prisma Client with `npx prisma generate`
6. Install Supabase SDK and configure BFF
7. Start building API routes (events, attendance, votes, feedback, dues, interviews)

**See `sql/migrations/README.md` for detailed migration instructions.**

---

## Design Decisions (Resolved)

✅ **Voting rounds** - Using flexible `voting_round` TEXT field (can formalize later if needed)
✅ **Event RSVP** - Added optional `rsvp_status` field to attendance table for future use
✅ **Candidate stages** - Added `candidate_stage` field to users table (migration 008)
✅ **Dues status** - Using: PAID, PARTIAL, NOT_PAID, OVERDUE, WAIVED
✅ **Interviews** - New table created (migration 007) with JSONB for flexible Q&A structure
✅ **Notifications** - Deferred to Phase 2 (future enhancement)

---

## v1 Core Features

Based on requirements, these features are prioritized for v1:

1. **Events Management** - Create and schedule rush events
2. **Attendance Tracking** - Mark who attended which events
3. **Voting System** - Secret ballot voting on candidates with multiple rounds
4. **Feedback** - Written feedback and ratings on candidates
5. **Interviews** - Structured interview content and assessments ⭐ **Critical for v1**
6. **Dues Tracking** - Payment status tracking
7. **Candidate Progression** - Track rushees through stages (FIRST_ROUND → BID_EXTENDED, etc.)
