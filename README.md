# Rush Backend (BFF)

## Overview

This is the **Backend-for-Frontend (BFF)** service powering the **Rush App** — a cross-platform system for fraternity recruitment workflows.

It serves two frontends:

1. **Mobile (React Native + Expo)** — used by members and candidates.
2. **Web (Next.js)** — used by admins and rush chairs.

The backend provides a unified API that mediates between:

- Supabase (auth + database)
- Internal logic (attendance, votes, dues, feedback, etc.)
- Third-party integrations (if added later)

## Tech Stack

- **Language:** TypeScript (Node.js)
- **Framework:** Express.js
- **Database:** Supabase (PostgreSQL)
- **ORM:** Prisma (optional)
- **Environment:** dotenv for secrets
- **Package Manager:** pnpm (recommended) or npm

## Project Structure (tbd)

```txt
rush-backend/
│
├── src/
│   ├── index.ts           # entrypoint
│   ├── routes/            # route handlers
│   ├── services/          # business logic
│   ├── utils/             # helpers
│   └── config/            # env, supabase, prisma
│
├── prisma/                # schema.prisma if ORM used
│
├── .env                   # placeholder env vars
├── .gitignore
├── package.json
├── tsconfig.json
└── README.md
```

## Goals

- Provide unified, secure API for Rush app and any other future applications.
- Simplify Supabase queries via backend routes.
- Standardize auth, roles, and validation logic.
- Prepare for both Expo (mobile) and Next.js (web) clients.
