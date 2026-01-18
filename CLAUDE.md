# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Backend-for-Frontend (BFF)** service for the **Rush App** — a cross-platform fraternity recruitment workflow system. It provides a unified API layer that mediates between:
- Mobile frontend (React Native + Expo) for members and candidates
- Web frontend (Next.js) for admins and rush chairs
- Supabase backend (auth + PostgreSQL database)
- Internal business logic (events, attendance, votes, feedback, interviews, dues)

## Technology Stack Decision

**Stack:** Node.js + TypeScript + Express.js

This project uses Node.js/TypeScript and will NOT be migrated to other languages (e.g., Go). This decision is intentional and based on architectural integration requirements:

### Key Integration Reasons
1. **Type Sharing** - TypeScript types are shared across the full stack (mobile React Native, web Next.js, and this BFF). Migrating to another language would break this type safety and require duplicate definitions or code generation.

2. **Supabase Integration** - Supabase provides first-class TypeScript support via `@supabase/supabase-js`. The Node.js ecosystem has mature auth, real-time, and RLS integration that would need to be rebuilt in other languages.

3. **BFF Pattern Fit** - BFFs are I/O-bound (HTTP aggregation, JSON transformation, session management). Node.js's event loop and middleware ecosystem excel at this pattern.

4. **Ecosystem Velocity** - Express.js has battle-tested middleware for auth, validation, rate limiting, and error handling. This enables faster feature development than rebuilding these patterns in other frameworks.

### Future Microservices
If performance-critical or CPU-intensive services are needed (analytics aggregation, bulk notifications, report generation), those should be built as **separate microservices** in appropriate languages (Go, Rust) that call into or are called by this BFF.

**See `reports/migration-analysis.md` for detailed reasoning and architectural tradeoffs.**

## Development Commands

### Essential Commands
- `pnpm install` - Install dependencies (respects lockfile)
- `pnpm dev` - Start development server with hot reload on port 4000
- `pnpm build` - Compile TypeScript to `dist/` directory
- `pnpm start` - Run compiled production build
- `pnpm lint` - Run ESLint + Prettier checks
- `pnpm test` - Run tests (currently placeholder, will use Jest + Supertest)

### Environment Setup
Copy `.env.example` to `.env` and populate:
- `PORT` - Server port (default: 4000)
- `NODE_ENV` - Environment mode (development/production)
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_ANON_KEY` - Public anonymous key
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key (never commit!)
- `DATABASE_URL` - PostgreSQL connection string for Prisma (get from Supabase project settings)

## Architecture

**See `reports/architecture-vision.md` for full system architecture, integration patterns, and future microservices strategy.**

### Request Flow
1. Express app (`src/index.ts`) bootstraps with JSON middleware
2. All routes mount under `/api` prefix
3. Routes delegate to route registration functions (e.g., `registerHealthRoutes`)
4. Route handlers call service layer functions for business logic
5. Services interact with Supabase or other data sources

### Module Organization Pattern
The codebase follows a **feature-based co-location** pattern:

```
src/
├── routes/          # HTTP endpoint registration
│   ├── health.ts    # registerHealthRoutes()
│   └── index.ts     # Central router that imports all route modules
├── services/        # Business logic layer
│   └── health/      # Feature-specific service
│       └── index.ts
├── config/          # Environment and configuration
│   ├── env.ts       # appConfig with Supabase settings
│   └── index.ts
└── utils/           # Shared utilities
    └── logger.ts
```

**Key principle**: Keep related functionality together. When adding a new feature (e.g., "votes"), create:
- `src/routes/votes.ts` - Route registration function
- `src/services/votes/` - Business logic module
- Register routes in `src/routes/index.ts`

### Configuration System
- All config centralized in `src/config/env.ts` as `appConfig` object
- Dotenv loads from `.env` file
- Provides type-safe accessors with fallback defaults
- Supabase credentials available at `appConfig.supabase.*`

### TypeScript Module System
- Uses ES modules (`"type": "module"` in package.json)
- All imports must include `.js` extension (TypeScript convention for ES modules)
- Example: `import routes from './routes/index.js'`
- Compiles to NodeNext module resolution

## Code Style

### Naming Conventions
- **camelCase**: variables, functions (`getHealthStatus`, `appConfig`)
- **PascalCase**: classes, types, interfaces (`Router`, `RequestHandler`)
- **SCREAMING_SNAKE_CASE**: environment constants only
- **Route registration pattern**: Use `register{Feature}Routes(router: Router)` pattern

### File Structure
- Use 2-space indentation
- One feature per module with single entry point (`index.ts`)
- Place tests beside code using `*.spec.ts` naming
- Integration tests go in `tests/` directory

### Documentation
- Add concise JSDoc for route handlers describing request/response DTOs
- Document non-obvious business logic
- Avoid comments for self-evident code

## Testing Strategy

### When Tests Are Added
- Use Jest + Supertest framework
- Mock Supabase via fixtures in `tests/fixtures/`
- Place unit tests in `__tests__/` subdirectories or as `*.spec.ts` files
- Maintain ≥80% statement coverage
- Use behavior-driven descriptions: `describe('attendance submission')`
- Run tests with `pnpm test --watch` while developing
- Verify coverage with `pnpm test --coverage`

## Database & Prisma

### Current State
- **Database:** PostgreSQL via Supabase
- **ORM:** Prisma for type-safe database access
- **Schema Documentation:** See `docs/database-schema.md` for complete database design
- **Migrations:** SQL migration files in `sql/migrations/` directory
- **Migration Guide:** See `sql/migrations/README.md` and `sql/MIGRATION_CHECKLIST.md`

### Database Schema (v1)

The database consists of 7 core tables for rush management:

1. **users** - User profiles linked to Supabase Auth (roles: ADMIN, ACTIVE, PLEDGE, RUSHEE)
2. **events** - Rush events (dinners, smokers, interviews, meetings)
3. **attendance** - Event attendance tracking with optional RSVP support
4. **votes** - Secret ballot voting on candidates with multiple rounds
5. **feedback** - Written feedback and ratings (1-5 stars) on candidates
6. **dues_payments** - Financial tracking (statuses: PAID, PARTIAL, NOT_PAID, OVERDUE, WAIVED)
7. **interviews** - Interview content, assessments, and recommendations (JSONB for flexible Q&A)

**Additional Features:**
- `candidate_stage` field on users tracks rushee progression (INITIAL → FIRST_ROUND → BID_EXTENDED → etc.)
- Row Level Security (RLS) enabled on all tables
- Automated `updated_at` triggers on all tables
- Comprehensive indexes for performance

### Available Migrations

All migrations are ready to run in `sql/migrations/`:

- ✅ `001_create_users_table.sql` - User profiles and auth
- ✅ `002_create_events_table.sql` - Rush events
- ✅ `003_create_attendance_table.sql` - Attendance tracking
- ✅ `004_create_votes_table.sql` - Voting system
- ✅ `005_create_feedback_table.sql` - Member feedback
- ✅ `006_create_dues_payments_table.sql` - Financial tracking
- ✅ `007_create_interviews_table.sql` - Interview assessments
- ✅ `008_add_candidate_stage_to_users.sql` - Candidate progression tracking

**To run migrations:** Follow the step-by-step guide in `sql/MIGRATION_CHECKLIST.md`

### Setting Up Prisma

After running database migrations in Supabase:

```bash
# 1. Install Prisma dependencies
pnpm add @prisma/client
pnpm add -D prisma

# 2. Ensure DATABASE_URL is set in .env
# DATABASE_URL="postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"

# 3. Pull schema from Supabase (introspects database)
npx prisma db pull

# 4. Generate Prisma Client with TypeScript types
npx prisma generate

# 5. Verify types are available
# You should now have autocomplete for:
# - prisma.users
# - prisma.events
# - prisma.attendance
# - prisma.votes
# - prisma.feedback
# - prisma.dues_payments
# - prisma.interviews
```

### When Adding Database Features

1. **For new tables:** Create new migration file with sequential numbering (e.g., `009_create_xyz_table.sql`)
2. **For schema changes:** Use `ALTER TABLE` in a new migration file
3. **Update Prisma:** Run `npx prisma db pull` to sync schema
4. **Regenerate client:** Run `npx prisma generate` to update TypeScript types
5. **Reference migration ID** in PR descriptions
6. **Test thoroughly** before merging database changes

## v1 Core Features (Implementation Roadmap)

These features are prioritized for the initial release:

### Phase 1: Foundation (Weeks 1-2)
- ✅ Database migrations (all 8 migrations created)
- [ ] Supabase SDK integration (`src/config/supabase.ts`)
- [ ] Authentication middleware (`src/middleware/auth.ts`)
- [ ] Prisma Client setup
- [ ] Test framework configuration (Jest + Supertest)

### Phase 2: Events & Attendance (Weeks 2-3)
- [ ] Events API (`POST /api/events`, `GET /api/events`, `GET /api/events/:id`, `PATCH /api/events/:id`)
- [ ] Attendance API (`POST /api/attendance`, `GET /api/attendance/event/:eventId`, `GET /api/attendance/user/:userId`)
- [ ] Service layer for events and attendance
- [ ] Tests for events and attendance routes

### Phase 3: Voting System (Weeks 3-4)
- [ ] Voting API (`POST /api/votes/ballot`, `GET /api/votes/candidate/:candidateId`, `GET /api/votes/results/:eventId`)
- [ ] Vote validation (prevent duplicate votes, enforce active member voting)
- [ ] Aggregated results queries (respect anonymity)
- [ ] Tests for voting routes

### Phase 4: Feedback & Interviews (Weeks 4-5) ⭐ **Critical for v1**
- [ ] Feedback API (`POST /api/feedback`, `GET /api/feedback/candidate/:candidateId`)
- [ ] Interviews API (`POST /api/interviews`, `GET /api/interviews/candidate/:candidateId`, `GET /api/interviews/:id`)
- [ ] Support for JSONB interview Q&A structure
- [ ] Tests for feedback and interviews

### Phase 5: Dues & Admin Features (Weeks 5-6)
- [ ] Dues API (`POST /api/dues/payment`, `GET /api/dues/user/:userId`, `GET /api/dues/outstanding`)
- [ ] Admin dashboard stats (`GET /api/admin/stats`)
- [ ] Candidate stage tracking (`PATCH /api/users/:id/stage`)
- [ ] Tests for dues and admin routes

### Phase 6: Polish & Deploy (Weeks 6-7)
- [ ] Error handling middleware
- [ ] Input validation (Zod schemas)
- [ ] Rate limiting
- [ ] API documentation
- [ ] Production deployment (Render/Railway/Vercel)

**See `docs/database-schema.md` for detailed feature specifications and business rules.**

## Security & Environment

### Critical Rules
- Never commit `.env` files or Supabase service keys
- Store secrets in deployment platform (Vercel/Render)
- Rotate Supabase tokens after security incidents
- Encapsulate third-party credentials under `config/`

### Authentication
- Central auth middleware will be added to `src/routes/index.ts`
- All protected routes should use this middleware
- Service role key used for server-side operations only

## Commit Conventions

Follow existing short, imperative style:
- Keep subject ≤50 characters
- Use format: `feat(scope): description` or simple imperative
- Examples: `feat(votes): add ballot routes`, `fix: handle null timestamps`
- Reference issues in body: `Closes #123`

## Pull Request Requirements

Every PR should include:
1. Summary of changes
2. Validation steps (`pnpm test`, `pnpm lint` passing)
3. curl examples or screenshots for new endpoints
4. Supabase migration IDs if applicable
5. Request review from backend maintainer

## Adding New Features

### Checklist for New Endpoints

1. **Create service module:** `src/services/{feature}/index.ts`
   - Use Prisma Client for database queries
   - Implement business logic and validation
   - Handle errors appropriately

2. **Create route registration:** `src/routes/{feature}.ts`
   - Use `register{Feature}Routes(router: Router)` pattern
   - Apply auth middleware for protected routes
   - Add input validation (Zod schemas recommended)

3. **Register routes:** Import and register in `src/routes/index.ts`

4. **Add tests:** `src/routes/__tests__/{feature}.spec.ts`
   - Use Jest + Supertest
   - Mock Prisma Client
   - Test success and error cases

5. **Document:** Add JSDoc for request/response DTOs

6. **Database changes (if needed):**
   - Create new migration file in `sql/migrations/`
   - Run migration in Supabase
   - Update Prisma schema with `npx prisma db pull`
   - Regenerate client with `npx prisma generate`

7. **Validate:** Run `pnpm lint` and `pnpm test` before committing

### Example Route Pattern

```typescript
// src/routes/votes.ts
import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { submitBallot } from '../services/votes/index.js';

export const registerVotesRoutes = (router: Router): void => {
  // Protected route - requires authentication
  router.post('/votes/ballot', authMiddleware, async (req, res) => {
    try {
      const result = await submitBallot(req.body, req.user);
      res.json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
};

// src/routes/index.ts
import { registerVotesRoutes } from './votes.js';
registerVotesRoutes(router);
```

```typescript
// src/services/votes/index.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function submitBallot(data: any, user: any) {
  // Validate user is ACTIVE member
  if (user.role !== 'ACTIVE') {
    throw new Error('Only active members can vote');
  }

  // Check for duplicate vote
  const existing = await prisma.votes.findFirst({
    where: {
      voter_id: user.id,
      candidate_id: data.candidate_id,
      voting_round: data.voting_round,
    },
  });

  if (existing) {
    throw new Error('You have already voted in this round');
  }

  // Create vote
  return await prisma.votes.create({
    data: {
      voter_id: user.id,
      candidate_id: data.candidate_id,
      vote_type: data.vote_type,
      voting_round: data.voting_round,
      vote_value: data.vote_value,
    },
  });
}
```

## Key Documentation Files

- **`CLAUDE.md`** - This file (project guidelines for Claude Code)
- **`README.md`** - Project overview and getting started
- **`docs/database-schema.md`** - Complete database schema design with tables, relationships, and business rules
- **`sql/migrations/README.md`** - How to run database migrations (3 methods)
- **`sql/MIGRATION_CHECKLIST.md`** - Step-by-step migration execution checklist with verification commands
- **`reports/architecture-vision.md`** - System architecture, integration patterns, and future microservices strategy
- **`reports/migration-analysis.md`** - Why we chose Node.js/TypeScript over other languages

## Quick Start for New Developers

1. **Clone and install:**
   ```bash
   git clone <repo-url>
   cd bff
   pnpm install
   ```

2. **Set up environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your Supabase credentials
   ```

3. **Run database migrations:**
   - Follow `sql/MIGRATION_CHECKLIST.md`
   - Run all 8 migrations in Supabase SQL Editor

4. **Set up Prisma:**
   ```bash
   pnpm add @prisma/client
   pnpm add -D prisma
   npx prisma db pull
   npx prisma generate
   ```

5. **Start development server:**
   ```bash
   pnpm dev
   # Server runs on http://localhost:4000
   ```

6. **Verify setup:**
   ```bash
   curl http://localhost:4000/api/health
   # Should return: {"status":"healthy"}
   ```

7. **Start building features** following the v1 roadmap above!
