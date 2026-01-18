# Reports & Architecture Documentation

This directory contains architectural decisions, analysis reports, and planning documents for the Rush App BFF.

## Active Documents

### [architecture-vision.md](./architecture-vision.md)
**Purpose:** Full system architecture documentation
**Contents:**
- Current architecture diagram (Phase 1)
- Future architecture with microservices (Phase 2+)
- Integration patterns (sync, async, event-driven)
- Technology recommendations for future services
- Anti-patterns to avoid
- Decision log

**Use this when:**
- Planning new services or features
- Evaluating technology choices
- Understanding system integration points
- Deciding whether to add microservices

---

### [migration-analysis.md](./migration-analysis.md)
**Purpose:** Detailed analysis of why we chose Node.js/TypeScript over Go
**Contents:**
- Current state assessment (76 LOC, minimal deps)
- 9 criteria comparison (type sharing, Supabase integration, etc.)
- Scoring matrix (8/9 favor TypeScript)
- Counterarguments addressed
- Recommended polyglot architecture

**Use this when:**
- Someone questions the technology choice
- Evaluating future rewrites or migrations
- Understanding tradeoffs between Node.js and Go
- Making language choices for new services

---

### [potential-rush-cli.md](./potential-rush-cli.md)
**Purpose:** Specification for a future Go CLI tool
**Contents:**
- Concrete use cases (bulk imports, reports, admin tasks)
- Why Go is perfect for CLI tools
- Learning benefits
- Architecture integration
- Example code structure
- Recommended tech stack (Cobra, pgx, etc.)

**Use this when:**
- Ready to build administrative tooling
- Learning Go in a practical context
- Need bulk operations or automation
- Rush chairs request command-line tools

---

## Archive

### [archive/migration-plan.md](./archive/migration-plan.md)
**Purpose:** Original migration proposal (Node.js → Go)
**Status:** ❌ Rejected
**Contents:**
- Step-by-step migration plan
- Benefits claimed for Go
- Directory structure mapping

**Historical reference only.** Not recommended for implementation.

---

## Quick Reference

### Why This Stack?
Node.js/TypeScript was chosen for:
1. **Type sharing** across React Native mobile, Next.js web, and BFF
2. **Supabase integration** (first-class TypeScript SDK)
3. **BFF pattern fit** (I/O-bound HTTP aggregation)
4. **Ecosystem velocity** (Express middleware, testing, tooling)

See: [migration-analysis.md](./migration-analysis.md)

### When to Add Go Services?
Add Go microservices only when you have **measured performance problems**:
- Analytics aggregation (CPU-bound)
- High-throughput notifications (1000+/min)
- PDF report generation (CPU-intensive)
- CLI tools for admins (single binary distribution)

See: [architecture-vision.md](./architecture-vision.md)

### Integration Patterns
- **Sync:** User request → BFF → Service → Response (real-time)
- **Async:** BFF → Queue → Service (background jobs)
- **Event:** BFF → Event → Multiple subscribers (fan-out)

See: [architecture-vision.md](./architecture-vision.md#integration-patterns)

---

## Document Status

| Document | Last Updated | Status |
|----------|--------------|--------|
| architecture-vision.md | 2026-01-18 | ✅ Active |
| migration-analysis.md | 2026-01-18 | ✅ Active |
| potential-rush-cli.md | 2026-01-18 | 📋 Planned (future) |
| archive/migration-plan.md | 2024-11 (est.) | 🗄️ Archived |

---

## Adding New Reports

When creating new documentation:

1. **Active documents** go in `reports/` root
2. **Deprecated/historical** go in `reports/archive/`
3. **Update this README** with summary and links
4. **Reference from CLAUDE.md** if it affects development workflow

### Naming Convention
- `{topic}-{type}.md` (e.g., `authentication-design.md`, `testing-strategy.md`)
- Use lowercase with hyphens
- Be descriptive but concise
