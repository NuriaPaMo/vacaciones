# ADR-003: Use Azure SQL Database with EF Core (Writes) and Dapper (Reads)

## Status

Accepted

## Date

2026-08-05

## Context

The application requires a relational data store for structured domain data (e.g., reservations, users, products). The architecture follows a CQRS pattern (ADR-002) with a clear separation between command (write) and query (read) sides. The project is Azure-hosted and follows an Azure-first strategy (ADR-001).

Key requirements:
- **Relational model**: Domain data is naturally relational with foreign keys and transactional consistency requirements
- **Write safety**: Command side requires transactional guarantees, change tracking, and optimistic concurrency
- **Read performance**: Query side requires optimised, projection-based reads — full ORM hydration overhead is unnecessary
- **Schema evolution**: Migrations must be version-controlled and reproducible across environments
- **Azure-native**: Managed service reduces operational burden (backups, patching, HA)

Key forces:
- EF Core change tracking is valuable for writes but adds overhead for reads
- Raw SQL via Dapper provides maximum control and performance for read projections
- Repository + Unit of Work patterns decouple domain logic from persistence infrastructure
- EF Core Migrations provide a single source of truth for schema evolution

## Decision Drivers

- MUST use a relational database (domain model is relational)
- MUST support transactional writes with optimistic concurrency
- MUST support fast, projection-based reads without full entity hydration
- MUST run on Azure as a managed service
- MUST version-control schema changes as code
- SHOULD separate read and write data access models explicitly

## Considered Options

### Option 1: Azure SQL Database + EF Core (writes) + Dapper (reads) ✅ (Chosen)

Azure SQL Database is the Azure-managed offering of SQL Server. EF Core handles the command side (writes) with full change tracking, relationships, and migrations. Dapper handles the query side (reads) with lightweight, projection-focused SQL queries.

**Pros:**
- Azure SQL provides SLA-backed HA, automated backups, point-in-time restore, and geo-redundancy
- EF Core change tracking ensures write correctness, concurrency tokens, and relationship management
- EF Core Migrations provide a code-first, version-controlled schema evolution workflow
- Dapper is a micro-ORM with near-raw SQL performance — ideal for read projections and reporting queries
- Repository + Unit of Work patterns abstract persistence from domain logic, enabling testable command handlers
- Both EF Core and Dapper are first-class .NET libraries with mature Azure SQL drivers
- Perfect alignment with CQRS (ADR-002): write model = EF Core entities, read model = Dapper DTOs

**Cons:**
- Two data access libraries to maintain (EF Core + Dapper) — mitigated by clear CQRS boundary: EF Core in command handlers only, Dapper in query handlers only
- Dapper requires writing SQL by hand — no query generation; mitigated by testability and explicit control
- Azure SQL incurs cost vs. self-hosted SQL Server — justified by managed operations value

### Option 2: Azure SQL Database + EF Core Only

**Pros:**
- Single library to learn and maintain
- LINQ queries for both reads and writes
- Familiar to most .NET developers

**Cons:**
- EF Core LINQ-to-SQL generates suboptimal queries for complex read projections (N+1 risks, unnecessary JOINs)
- Change tracking enabled even for read-only queries unless explicitly disabled with `.AsNoTracking()` (easy to forget)
- Less control over read query performance — harder to optimise without raw SQL
- Blurs the CQRS read/write separation boundary

### Option 3: Azure Cosmos DB (NoSQL)

**Pros:**
- Globally distributed, multi-region writes
- Schema-less, flexible document model

**Cons:**
- Domain model is relational — NoSQL requires denormalisation, duplicated data, and consistency trade-offs
- No transactional guarantees across partitions
- More expensive at moderate data volumes vs. Azure SQL
- EF Core for Cosmos is significantly less mature than EF Core for SQL Server
- Adds operational complexity without a corresponding benefit for this use case

### Option 4: PostgreSQL (self-managed or Azure Database for PostgreSQL)

**Pros:**
- Open source, no vendor lock-in
- Excellent EF Core support via Npgsql
- Strong JSON, full-text search, and extension ecosystem

**Cons:**
- Azure-first strategy (ADR-001) favours Azure-native services; Azure SQL aligns better with existing Azure enterprise agreements and tooling
- Azure Database for PostgreSQL Flexible Server is a valid alternative but lacks the breadth of Azure SQL integration with Azure DevOps, Microsoft Entra, and the Azure SDK
- Team likely has stronger SQL Server/Azure SQL familiarity in a Microsoft-ecosystem project

## Decision Outcome

**Chosen option: Azure SQL Database + EF Core (writes) + Dapper (reads)**

Rationale: Azure SQL provides a fully managed, SLA-backed relational store that integrates natively with the Azure ecosystem. EF Core delivers write correctness through change tracking and schema evolution through Migrations. Dapper maximises read query performance with explicit SQL. The combination maps perfectly to the CQRS read/write split and avoids the performance pitfalls of using a full ORM for read projections.

### Patterns Applied

| Pattern | Purpose |
|---------|---------|
| Repository | Abstracts persistence from domain logic; interface defined in domain, implementation in Persistence layer |
| Unit of Work | Groups multiple repository operations into a single transaction (EF Core `DbContext` is the UoW) |
| EF Core Migrations | Version-controlled, code-first schema evolution applied via `dotnet ef migrations` in CI/CD |
| Read DTOs | Dapper maps directly to lightweight DTO classes, not EF Core entities |

### Positive Consequences

- Read query performance optimised — Dapper with hand-crafted SQL for projections avoids N+1 and over-fetching
- Write safety guaranteed — EF Core change tracking, optimistic concurrency tokens, and transactions
- Schema evolution is code-reviewed and auditable via EF Core Migrations committed to source control
- Azure SQL managed service eliminates DBA operational burden (patching, backups, HA failover)
- Repository interfaces enable unit testing of command handlers without a real database
- Clear CQRS boundary: EF Core `DbContext` injected only into command handlers; Dapper connection injected only into query handlers

### Negative Consequences

- Two libraries to maintain (EF Core + Dapper) — acceptable given the clear boundary
- Dapper queries are strings — no compile-time SQL validation; mitigated by integration tests against a real DB in CI
- EF Core Migrations require care during concurrent feature development — team must coordinate migration files to avoid conflicts

## Compliance

- Architecture: Aligns with CQRS write/read split (ADR-002)
- Infrastructure: Azure SQL provisioned via Terraform (ADR-005)
- Security: Connection strings stored in Azure Key Vault, accessed via managed identity (ADR-006)

## Links

- [EF Core documentation](https://learn.microsoft.com/en-us/ef/core/)
- [Dapper documentation](https://github.com/DapperLib/Dapper)
- [Azure SQL Database documentation](https://learn.microsoft.com/en-us/azure/azure-sql/)
- [EF Core Migrations](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/)
- ADR-002: Backend Architecture — Modular Monolith with Simple CQRS
- ADR-005: Cloud Infrastructure — Azure Container Apps with Terraform
- ADR-006: CI/CD, Observability, and Security Baseline
