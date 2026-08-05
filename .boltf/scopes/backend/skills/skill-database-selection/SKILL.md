---
name: skill-database-selection
description: Choose database (SQL vs NoSQL) and ORM patterns (Entity Framework Core, Dapper, Prisma, TypeORM) for .NET and Node.js applications. Use when selecting Azure SQL, PostgreSQL, Cosmos DB, or MongoDB, implementing repository patterns, or designing the data access layer. Critical decision affecting the entire data layer and difficult to migrate later.
---

# Database Selection

> **Constitution Articles**: Backend V §5.1-5.2 (Primary Database, Data Access Pattern)
> **Bundled Resources**: [Code Examples](references/code-examples.md) • [Microsoft Learn](references/microsoft-learn.md)

## When to Use This Skill

Database choice is one of the most expensive decisions to reverse. Migrating from SQL to NoSQL (or vice versa) after you've built domain logic around one model requires rewriting queries, rethinking transactions, and testing data integrity again from scratch. This skill helps you choose correctly the first time. Use this when:

- **Starting a new project or service** - because selecting the wrong database early leads to impedance mismatches between your data model and database capabilities, forcing workarounds throughout your codebase
- **Evaluating SQL vs NoSQL trade-offs** - because relational ACID guarantees and complex JOIN capabilities matter deeply for some workloads (financial transactions, inventory) while NoSQL flexibility and scale-out characteristics fit others (user profiles, telemetry, catalogs)
- **Choosing between Azure database offerings** - because Azure SQL Database, PostgreSQL, Cosmos DB, Table Storage, and Redis each excel in different scenarios and have vastly different cost structures at scale
- **Selecting an ORM or data access pattern** - because Entity Framework Core, Dapper, Prisma, and TypeORM make different trade-offs between developer productivity, performance, and type safety
- **Designing repository patterns** - because abstracting data access enables testability and potential future database migrations, but over-abstraction adds unnecessary ceremony for simple CRUD
- **Planning polyglot persistence** - because using multiple specialized databases (SQL for transactions, Redis for caching, Cosmos for global reads) is normal in distributed architectures, but coordination and consistency become complex

Database selection directly affects query capabilities, transaction semantics, scale characteristics, operational complexity, and cost. Wrong choices accumulate technical debt that compounds over time as data volume grows.

## Decision Framework

### Database Technology Selection

```text
What are your primary access patterns?

┌─ Transactional workloads (CRUD with relationships)
│   └─ What's your complexity level?
│       ├─ Complex queries (JOINs, aggregations, CTEs)
│       │   → SQL Database (relational algebra optimized for this)
│       ├─ Simple key-value or document lookups
│       │   └─ What's your scale?
│       │       ├─ <100K ops/sec + strong consistency
│       │       │   → SQL Database (good enough, simpler)
│       │       └─ >100K ops/sec OR global distribution
│       │           → Cosmos DB (horizontal scale, multi-region writes)
│       └─ Open-source preference OR cost-sensitive
│           → PostgreSQL (30-50% cheaper, JSON support, pgvector for AI)
│
├─ Analytical workloads (OLAP, data warehousing)
│   → See skill-data-platform-selection (Fabric, Databricks, Synapse)
│
├─ Caching / session state (sub-millisecond reads)
│   └─ What's your eviction strategy?
│       ├─ LRU cache with TTL
│       │   → Redis (distributed cache, pub/sub, sorted sets)
│       └─ Simple key-value with partitioning
│           → Table Storage (cheapest NoSQL, no indexing complexity)
│
└─ Event sourcing / append-only log
    → Cosmos DB (change feed for projections) OR Event Hubs (streaming)
```

### ORM and Data Access Selection

```text
What's your stack?

├─ .NET
│   └─ What's your performance requirement?
│       ├─ Developer productivity > raw performance
│       │   → Entity Framework Core (change tracking, migrations, LINQ)
│       ├─ Performance critical (high-frequency reads)
│       │   → Dapper (micro-ORM, 2-3x faster, manual mapping)
│       └─ Hybrid (write with EF, read with Dapper)
│           → Repository pattern (EF for commands, Dapper for queries)
│
└─ Node.js / TypeScript
    └─ What's your schema management approach?
        ├─ Code-first with type safety
        │   → Prisma (schema.prisma generates types, migrations, client)
        ├─ Database-first with decorators
        │   → TypeORM (entities map to tables, Active Record or Data Mapper)
        └─ SQL-first with raw queries
            → Knex.js (query builder) or node-postgres (raw SQL)
```

### Scoring Model: Database Fit Analysis

This scoring helps evaluate which database fits your context. Rate each factor 0-10 (higher = better fit). Use this as a conversation starter with your team about what truly matters for your workload, not as a rigid calculation:

| Factor                     | Azure SQL | PostgreSQL | Cosmos DB | Table Storage | Redis  |
| -------------------------- | --------- | ---------- | --------- | ------------- | ------ |
| Complex queries (JOINs)    | 10        | 10         | 2         | 1             | 1      |
| ACID transactions          | 10        | 10         | 7         | 1             | 3      |
| Schema flexibility         | 3         | 6          | 10        | 10            | 10     |
| Global distribution        | 5         | 4          | 10        | 7             | 6      |
| Sub-10ms reads (p99)       | 4         | 4          | 10        | 8             | 10     |
| Write throughput ceiling   | 50K/s     | 50K/s      | 1M+/s     | 100K/s        | 500K/s |
| Cost (equivalent workload) | $$$       | $$         | $$$$      | $             | $$     |

**Example scenario - E-commerce order management:**
SQL Database scores 10 (queries), 10 (ACID), 5 (global) = Best fit
Cosmos DB scores 2 (queries), 7 (ACID), 10 (global) = Poor fit (needs JOINs)
→ SQL Database wins because order-line-product relationships require relational algebra

**Example scenario - Global user profile service:**
Cosmos DB scores 10 (schema), 10 (global), 10 (latency) = Best fit
SQL Database scores 3 (schema), 5 (global), 4 (latency) = Poor fit
→ Cosmos DB wins because flexible schema + global replication critical

## Database Technologies

### Azure SQL Database

Azure SQL Database provides fully managed SQL Server with automatic backups, patching, high availability, and geo-replication. The relational model with ACID transactions and powerful query optimizer makes it the safest default for transactional workloads with structured data and complex relationships.

SQL Database excels when your data has clear relationships (orders belong to customers, line items belong to orders), queries require JOINs across multiple tables, strong consistency matters (financial ledgers, inventory counts), and your team has SQL expertise. Entity Framework Core provides change tracking, migrations, and LINQ query translation, accelerating development for typical CRUD operations.

The relational model's strength becomes a weakness when schema changes frequently (rigid migrations), write throughput exceeds single-server limits (vertical scaling only goes so far), or global distribution with local writes is required (geo-replication adds complexity and eventual consistency concerns).

**Why the constitution mandates Entity Framework Core:** For relational databases, EF Core provides type-safe queries (LINQ catches errors at compile time), automatic migrations (schema changes tracked in code), and change tracking (only modified fields generate SQL UPDATE statements). Dapper is permitted for performance-critical read paths where EF Core's object materialization overhead becomes measurable.

See bundled [Azure SQL Database patterns](references/code-examples.md#azure-sql-examples).

### Azure Database for PostgreSQL

PostgreSQL offers the same relational strengths as SQL Database with open-source licensing, lower costs (30-50% savings for equivalent workloads), and unique features: JSONB columns with indexing (hybrid relational-document model), full-text search, array types, and extensions like PostGIS (geospatial) and pgvector (vector similarity for AI).

PostgreSQL fits when your team prefers open-source ecosystems, you need cost optimization without sacrificing relational capabilities, or you're building AI applications that benefit from pgvector's native vector search (avoids separate vector store for small-scale RAG). JSONB columns enable flexible schema evolution within a relational framework - structured data in tables, semi-structured metadata in JSONB.

Trade-offs include slightly less integration with Azure-native tooling (Azure SQL Database has tighter Azure AD authentication), and EF Core with Npgsql adds a dependency layer compared to SQL Database's native provider.

**Why consider PostgreSQL:** When your workload fits in a relational model but you're optimizing for cost or need PostgreSQL-specific features (JSONB indexing, advanced SQL constructs), PostgreSQL delivers 80% of SQL Database's capabilities at 50% of the cost.

See bundled [PostgreSQL implementation patterns](references/code-examples.md#postgresql-examples).

### Azure Cosmos DB

Cosmos DB provides globally distributed NoSQL with turnkey multi-region replication, sub-10ms read latency SLAs (p99), and horizontal scale to millions of operations per second. The document model stores JSON natively with flexible schemas, enabling rapid iteration on data structures without schema migrations.

Cosmos DB excels when you need global distribution with multi-region writes (users worldwide accessing local replicas), unpredictable scale that requires elastic throughput (spike from 10K to 1M RPS), flexible schemas that evolve frequently (product catalogs with varying attributes), or event sourcing read models (change feed streams every document modification in real-time).

The document model's flexibility becomes a limitation when queries require JOINs (documents don't reference each other natively - application logic must perform joins), strong consistency across multiple documents is critical (eventual consistency is default; strong consistency trades off latency), or query patterns are unknown upfront (secondary indexes must be defined; wildcard indexing increases cost).

**Why Cosmos DB for specific scenarios:** When latency and scale requirements exceed relational database capabilities, or when your data model is naturally hierarchical (user profile with nested addresses, preferences, orders), Cosmos DB's document model aligns with your domain objects without object-relational mapping friction.

See bundled [Cosmos DB document patterns](references/code-examples.md#cosmosdb-examples).

### Azure Table Storage

Table Storage provides the cheapest NoSQL option with simple key-value semantics (PartitionKey + RowKey), no secondary indexes, and no query complexity. You pay only for storage and operations - no provisioned throughput or request units.

Table Storage fits for simple lookups by key (session state, user preferences keyed by user ID), logging and telemetry (append-only writes with partition key based on time buckets), or when cost is paramount and query flexibility isn't needed. Throughput scales to ~100K ops/sec per storage account.

The simplicity comes with constraints: no queries beyond PartitionKey + RowKey (scanning entire tables is expensive), no relationships or JOINs, and no ACID transactions across partitions. Cosmos DB's Table API provides a migration path if you outgrow Table Storage's limitations while keeping the same SDK.

**Why Table Storage for specific scenarios:** When your access pattern is purely key-based lookups and you need the absolute lowest cost per GB and operation, Table Storage delivers NoSQL capabilities at ~10% of Cosmos DB's cost.

See bundled [Table Storage patterns](references/code-examples.md#table-storage-examples).

### Redis (Azure Cache for Redis)

Redis provides sub-millisecond in-memory caching with data structures (strings, hashes, lists, sets, sorted sets) and pub/sub messaging. Use Redis to cache expensive database queries, store session state for web farms, implement distributed locks, or maintain leaderboards with sorted sets.

Redis fits as a caching layer (cache-aside pattern reduces database load by 80%+), session store for stateless web apps, or real-time features like pub/sub for chat notifications. Data persistence (AOF, RDB) enables treating Redis as a primary store for scenarios where data loss on cache eviction is acceptable.

Redis is not a primary database for critical data requiring durability guarantees - it's an in-memory cache that trades persistence for speed. Use Redis to accelerate reads, not as the single source of truth for data you can't afford to lose.

**Why Redis for caching:** When your database is the bottleneck for read-heavy workloads, adding Redis caching can reduce database load by 80%+ and improve response times from 100ms to 5ms by serving hot data from memory.

See bundled [Redis caching patterns](references/code-examples.md#redis-examples).

## ORM and Data Access Patterns

### Entity Framework Core

Entity Framework Core (EF Core) provides the richest ORM experience for .NET with LINQ query translation, change tracking, migrations, and navigation properties. Developer productivity is the primary benefit - write C# LINQ queries instead of SQL strings, automatic schema migrations, and relationships mapped to object graphs.

EF Core fits for standard CRUD applications, rapid prototyping, and teams prioritizing developer velocity over raw performance. For read-heavy workloads with complex queries, EF Core's object materialization overhead (10-30% slower than Dapper) becomes measurable at high scale.

**Constitution alignment per Article V.2:** EF Core is the mandated ORM for relational databases, with Dapper permitted for performance-critical query paths.

### Dapper (Micro-ORM)

Dapper provides raw SQL query execution with minimal object mapping overhead (2-3x faster than EF Core). You write raw SQL, Dapper maps results to C# objects. Use Dapper for read-heavy scenarios where performance matters (dashboards querying millions of rows, high-frequency API endpoints).

Dapper fits alongside EF Core: use EF Core for writes (change tracking, validation, migrations) and Dapper for reads (fast queries without overhead). The hybrid approach maximizes both developer productivity and runtime performance.

### Prisma (Node.js)

Prisma provides a type-safe database client generated from a declarative schema file (`schema.prisma`). The schema defines models, relations, and migrations - Prisma generates TypeScript types automatically, catching data access errors at compile time.

Prisma fits TypeScript projects where type safety is critical, migrations should be tracked as code, and you want auto-completion for database queries. The generated Prisma Client provides a fluent API that feels native to JavaScript/TypeScript.

### TypeORM (Node.js)

TypeORM uses decorators to map TypeScript classes to database tables (Active Record or Data Mapper patterns). It supports multiple databases (PostgreSQL, MySQL, SQL Server, SQLite) with the same API, making it portable across different environments.

TypeORM fits when you prefer decorator-based entity definitions over separate schema files, want Active Record pattern for rapid CRUD (entities have `.save()` and `.remove()` methods), or need database portability.

## Repository Pattern

The repository pattern abstracts data access behind interfaces, enabling unit testing without database dependencies and potential future database migrations. For simple CRUD applications, repositories add ceremony without clear benefit - EF Core's `DbContext` is already a repository abstraction.

Use repositories when you need to swap implementations (testing with in-memory stores, migrating from SQL to Cosmos), apply domain-driven design (repositories belong to aggregates), or enforce data access policies (row-level security, multi-tenancy filtering). Skip repositories when your data layer is straightforward CRUD - avoid premature abstraction.

## Polyglot Persistence

Using multiple databases in a single architecture is normal and expected. Example e-commerce system:

- **Azure SQL Database** - Orders, inventory, customers (ACID transactions, relationships)
- **Cosmos DB** - Product catalog (global distribution, flexible schema)
- **Redis** - Shopping cart session state, pricing cache (sub-millisecond reads)
- **Table Storage** - Audit logs, telemetry (append-only, low cost)

Don't force one database for everything. Match each data type to the optimal storage based on access patterns, consistency needs, and scale requirements. The complexity comes from managing consistency across stores and coordinating distributed transactions (saga patterns).

## Common Pitfalls

**Choosing NoSQL for relational data** - When your data has clear relationships and you need JOINs, forcing a document model leads to application-side joins and data duplication. Use relational databases for relational data.

**Choosing SQL for massive scale** - When write throughput exceeds 50K ops/sec or you need global multi-region writes, relational databases require complex sharding. Cosmos DB handles this natively.

**Over-abstracting with repositories** - For simple CRUD apps, `DbContext` is already an abstraction. Adding repositories without clear benefit creates ceremony and indirection.

**Ignoring cost structures** - Cosmos DB costs scale with throughput (Request Units), not storage. Table Storage costs scale with storage. A 1TB dataset with infrequent access costs dramatically different across databases.

**Mixing ORMs unnecessarily** - Switching between EF Core and Dapper within the same transaction complicates change tracking. Pick one for writes, optionally use the other for reads.

## Quick Reference

| Scenario                      | Database      | Why                                            |
| ----------------------------- | ------------- | ---------------------------------------------- |
| Orders, transactions, JOINs   | Azure SQL     | Relational model, ACID, query optimizer        |
| Open-source, cost-sensitive   | PostgreSQL    | 30-50% cheaper, JSONB, pgvector for AI         |
| Global reads, flexible schema | Cosmos DB     | Multi-region, sub-10ms latency, document model |
| Simple key-value, low cost    | Table Storage | Cheapest NoSQL, partition+row key only         |
| Caching, session state        | Redis         | In-memory, sub-ms latency, cache-aside pattern |
| .NET standard CRUD            | EF Core       | LINQ, migrations, change tracking              |
| .NET high-performance reads   | Dapper        | 2-3x faster, raw SQL, minimal mapping          |
| TypeScript type-safe client   | Prisma        | Generated types, schema.prisma, migrations     |
| TypeScript decorator-based    | TypeORM       | Active Record pattern, multi-DB support        |

## Bundled Resources

This skill includes supplemental resources with complete, production-ready implementations:

- **[Code Examples](references/code-examples.md)** - Full implementations for Azure SQL, PostgreSQL, Cosmos DB, Table Storage, Redis with EF Core, Dapper, Prisma, and TypeORM patterns
- **[Microsoft Learn Resources](references/microsoft-learn.md)** - Curated official documentation, best practices guides, migration guides, and performance optimization patterns

These resources provide copy-paste starting points aligned with constitution mandates. Reference them when implementing your chosen database and ORM strategy.
