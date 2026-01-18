# Architecture Vision: Rush App

**Last Updated:** 2026-01-18

## Current Architecture (Phase 1)

```
┌─────────────────────┐
│   Mobile Frontend   │
│  (React Native +    │
│      Expo)          │
└──────────┬──────────┘
           │
           │ HTTP/JSON
           │
┌──────────▼──────────┐         ┌─────────────────┐
│                     │         │                 │
│   Web Frontend      │────────►│   Supabase      │
│   (Next.js)         │         │   - PostgreSQL  │
│                     │         │   - Auth        │
└──────────┬──────────┘         │   - Storage     │
           │                    │   - Real-time   │
           │                    └─────────────────┘
           │ HTTP/JSON                    ▲
           │                              │
┌──────────▼──────────┐                   │
│                     │                   │
│    Node.js BFF      │───────────────────┘
│   (TypeScript +     │    Direct connection
│     Express)        │    via @supabase/supabase-js
│                     │
└─────────────────────┘
```

### Technology Decisions

| Component | Technology | Reasoning |
|-----------|-----------|-----------|
| BFF | Node.js + TypeScript | Type sharing, Supabase integration, I/O-bound workload |
| Mobile | React Native + Expo | Cross-platform, shared codebase, TypeScript types |
| Web Admin | Next.js | SSR/SSG, TypeScript, React ecosystem |
| Database | Supabase (PostgreSQL) | Managed auth, real-time, RLS policies |
| ORM | Prisma | Type-safe queries, migration management |

### Current Integration Points

1. **Type Sharing**
   - Shared TypeScript types package (future: `@rush/types`)
   - DTOs defined once, used across BFF, mobile, and web
   - Compile-time safety across entire stack

2. **Authentication Flow**
   - Supabase Auth handles token issuance
   - BFF validates JWT tokens via Supabase
   - Row-Level Security (RLS) enforced at database level

3. **Data Flow**
   - Frontends → BFF → Business logic validation → Supabase
   - BFF aggregates multiple Supabase queries when needed
   - BFF transforms responses to frontend-friendly formats

---

## Future Architecture (Phase 2+)

When performance bottlenecks or specific use cases emerge, introduce focused microservices:

```
┌─────────────┐
│   Mobile    │──┐
└─────────────┘  │
                 │
┌─────────────┐  │        ┌───────────────────────────┐
│  Web Admin  │──┼───────►│    Node.js BFF (TS)      │
└─────────────┘  │        │  - Auth middleware        │
                 │        │  - Request routing        │
┌─────────────┐  │        │  - Response aggregation   │
│  rush-cli   │──┘        └───────────┬───────────────┘
└─────────────┘                       │
    (Go)                              │
                          ┌───────────┼───────────┐
                          │           │           │
                    ┌─────▼─────┐     │     ┌─────▼─────────────┐
                    │ Supabase  │     │     │  Go Microservices │
                    │ (Primary) │     │     ├───────────────────┤
                    └───────────┘     │     │ • Analytics       │
                                      │     │ • Notifications   │
                                      │     │ • Report Gen      │
                                      │     │ • Batch Jobs      │
                                      │     └───────────────────┘
                                      │
                                ┌─────▼──────┐
                                │  Message   │
                                │  Queue     │
                                │  (Redis/   │
                                │   RabbitMQ)│
                                └────────────┘
```

### When to Add Microservices

Only introduce microservices when you have **concrete performance problems** or **specific use cases** that benefit:

#### Analytics Service (Go)
**Trigger:** Daily vote/attendance aggregation takes >5 seconds
**Why Go:** CPU-bound calculations, concurrent data processing
**Integration:**
- BFF calls via REST API for reports
- Cron job triggers via message queue
- Direct PostgreSQL connection for read-only analytics queries

#### Notification Service (Go)
**Trigger:** Need to send 500+ SMS/emails within 1 minute
**Why Go:** High-throughput concurrent HTTP requests, worker pools
**Integration:**
- BFF publishes to message queue
- Go service consumes queue, sends notifications
- Updates delivery status back to Supabase

#### Report Generator (Go)
**Trigger:** PDF generation blocks BFF response time
**Why Go:** CPU-intensive rendering, parallel generation
**Integration:**
- BFF queues report request
- Go service generates PDF asynchronously
- Stores in Supabase Storage, returns URL

#### CLI Tool (Go)
**Trigger:** Rush chairs need bulk admin operations
**Why Go:** Single binary distribution, fast execution
**Integration:**
- Can call BFF API for validated operations
- Can connect directly to Supabase for bulk queries
- Standalone for dev tasks (seeding, type gen)

---

## Anti-Patterns to Avoid

### ❌ Don't: Premature Microservices
- **Problem:** Introducing services before you have real performance issues
- **Cost:** Increased complexity, deployment overhead, distributed debugging
- **Solution:** Start monolithic (single BFF), split when you measure pain

### ❌ Don't: Language Hype-Driven Development
- **Problem:** Rewriting working code to use trendy languages
- **Cost:** Lost productivity, documentation debt, learning curve
- **Solution:** Choose languages based on problem fit, not resume-building

### ❌ Don't: Distributed Monolith
- **Problem:** Microservices that all call each other synchronously
- **Cost:** Latency multiplication, cascade failures, tight coupling
- **Solution:** Use message queues for async work, keep sync calls minimal

### ❌ Don't: Breaking Type Safety
- **Problem:** Using non-TypeScript services that require manual DTO sync
- **Cost:** Runtime errors, type drift, maintenance burden
- **Solution:** Generate types from OpenAPI/Protobuf if using other languages

---

## Integration Patterns

### Pattern 1: Synchronous Request (Real-time)
```
User Request → BFF → Microservice → BFF → Response
```
**Use for:** User-facing operations requiring immediate response
**Example:** Fetch analytics dashboard data

### Pattern 2: Asynchronous Background Job
```
User Request → BFF → Message Queue → Microservice
            ↓
         Response (202 Accepted)

Later: Microservice → Result stored → User polls/webhook
```
**Use for:** Long-running operations (PDF generation, batch emails)
**Example:** Generate end-of-season report

### Pattern 3: Event-Driven
```
BFF → Event published → Multiple services subscribe
```
**Use for:** Fan-out notifications, audit logging
**Example:** Candidate voted on → Update stats, send notification, log event

---

## Technology Recommendations for Future Services

| Service Type | Language | Framework/Libraries | Reasoning |
|--------------|----------|-------------------|-----------|
| CLI Tools | Go | Cobra, Viper, pgx | Single binary, great CLI UX |
| High-throughput APIs | Go | Gin, Echo | Concurrent request handling |
| Data processing | Go | Standard lib + goroutines | CPU-bound workloads |
| Real-time services | Go | Gorilla WebSocket | Efficient connection handling |
| ML/Analytics | Python | FastAPI, Pandas, scikit-learn | Rich ML ecosystem |
| Scheduled jobs | Go/Python | Standard lib + cron | Low resource overhead |

---

## Migration Path (If Needed)

If you ever **do** need to migrate parts of the system:

1. **Identify the bottleneck** - Profile and measure (don't guess)
2. **Extract a service** - Start with smallest isolated piece
3. **Add API contracts** - OpenAPI spec, versioning
4. **Gradual cutover** - Feature flag, A/B test, monitor
5. **Validate** - Ensure performance actually improved
6. **Iterate** - Move more functionality if validated

**Never rewrite the entire BFF.** Extract services incrementally.

---

## Decision Log

| Date | Decision | Reasoning |
|------|----------|-----------|
| 2026-01-18 | Stick with Node.js/TypeScript BFF | Type sharing, Supabase integration, I/O-bound fit |
| 2026-01-18 | Reserve Go for future microservices | CPU-bound tasks, CLI tools, high-throughput services |
| TBD | Add analytics service? | Wait for measured performance need |
| TBD | Add notification service? | Wait for scale requirement (>100/min) |

---

## Questions for Future Evaluation

Before adding any microservice, answer:

1. **What specific problem are we solving?** (Measured with metrics)
2. **Have we optimized the current solution?** (Database indexes, caching, query optimization)
3. **What's the complexity cost?** (New deployment, monitoring, debugging)
4. **Could we solve it within the BFF?** (Background jobs, worker threads)
5. **Is this language the right fit?** (I/O vs CPU bound, library ecosystem)

**Default to simplicity.** Only add complexity when simplicity fails measurably.
