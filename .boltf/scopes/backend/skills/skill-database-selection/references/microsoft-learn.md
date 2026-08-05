# Database Selection – Microsoft Learn Resources

Curated Microsoft Learn documentation for each database technology. These resources provide official guidance, best practices, migration guides, and performance optimization strategies.

---

## Azure SQL Database

### Core Documentation

- **[What is Azure SQL Database?](https://learn.microsoft.com/azure/azure-sql/database/sql-database-paas-overview)**
  Overview of features, service tiers, and purchasing models

- **[Quickstart: Create an Azure SQL Database single database](https://learn.microsoft.com/azure/azure-sql/database/single-database-create-quickstart)**
  Step-by-step guide to creating your first SQL Database

- **[Connect and query Azure SQL Database using C# and ADO.NET](https://learn.microsoft.com/azure/azure-sql/database/connect-query-dotnet-core)**
  C# connectivity patterns with ADO.NET

### Entity Framework Core Integration

- **[Getting Started with EF Core](https://learn.microsoft.com/ef/core/get-started/overview/first-app)**
  Official EF Core tutorial (mandated ORM per constitution)

- **[EF Core Database Providers - SQL Server](https://learn.microsoft.com/ef/core/providers/sql-server/)**
  SQL Server-specific EF Core features and limitations

- **[Migrations in EF Core](https://learn.microsoft.com/ef/core/managing-schemas/migrations/)**
  Schema evolution with code-first migrations

- **[Connection resiliency in EF Core](https://learn.microsoft.com/ef/core/miscellaneous/connection-resiliency)**
  Retry policies for transient fault handling

### Performance & Optimization

- **[Performance best practices for SQL Database](https://learn.microsoft.com/azure/azure-sql/database/performance-guidance)**
  Indexing, query tuning, and monitoring guidance

- **[Automatic tuning in Azure SQL Database](https://learn.microsoft.com/azure/azure-sql/database/automatic-tuning-overview)**
  AI-powered index and query plan recommendations

- **[Elastic pools for Azure SQL Database](https://learn.microsoft.com/azure/azure-sql/database/elastic-pool-overview)**
  Share resources across multiple databases

### Security & Identity

- **[Passwordless connections with DefaultAzureCredential](https://learn.microsoft.com/azure/azure-sql/database/authentication-aad-configure)**
  Managed identity authentication (no connection strings)

- **[Row-level security in SQL Database](https://learn.microsoft.com/sql/relational-databases/security/row-level-security)**
  Filter rows based on user context

---

## Azure Database for PostgreSQL

### Core Documentation

- **[What is Azure Database for PostgreSQL?](https://learn.microsoft.com/azure/postgresql/flexible-server/overview)**
  Flexible Server overview (recommended deployment option)

- **[Quickstart: Create Azure Database for PostgreSQL](https://learn.microsoft.com/azure/postgresql/flexible-server/quickstart-create-server-portal)**
  Provision PostgreSQL Flexible Server

- **[Connect to Azure Database for PostgreSQL with C#](https://learn.microsoft.com/azure/postgresql/flexible-server/connect-csharp)**
  Npgsql connection patterns

### Entity Framework Core with PostgreSQL

- **[EF Core Database Providers - Npgsql (PostgreSQL)](https://www.npgsql.org/efcore/index.html)**
  Official Npgsql EF Core provider documentation

- **[PostgreSQL JSON Types with EF Core](https://www.npgsql.org/efcore/mapping/json.html)**
  JSONB column mapping and querying

- **[PostgreSQL Arrays with EF Core](https://www.npgsql.org/efcore/mapping/array.html)**
  Native array type support

### PostgreSQL-Specific Features

- **[Full-text search in PostgreSQL](https://www.postgresql.org/docs/current/textsearch.html)**
  Built-in search capabilities with tsvector/tsquery

- **[PostgreSQL Performance Tuning](https://learn.microsoft.com/azure/postgresql/flexible-server/concepts-query-store)**
  Query Store for performance monitoring

- **[pgvector extension for AI workloads](https://learn.microsoft.com/azure/postgresql/flexible-server/how-to-use-pgvector)**
  Vector similarity search for embeddings

---

## Azure Cosmos DB

### Core Documentation

- **[Welcome to Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/introduction)**
  Overview of globally distributed, multi-model database

- **[Choose an API in Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/choose-api)**
  NoSQL, MongoDB, Cassandra, Gremlin, Table API comparison

- **[Quickstart: Azure Cosmos DB for NoSQL with .NET](https://learn.microsoft.com/azure/cosmos-db/nosql/quickstart-dotnet)**
  Getting started with the NoSQL API (recommended)

### Cosmos DB SDK (.NET)

- **[Azure Cosmos DB .NET SDK v3](https://learn.microsoft.com/azure/cosmos-db/nosql/sdk-dotnet-v3)**
  Official SDK documentation and samples

- **[Pagination in Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/nosql/query/pagination)**
  Continuation tokens and result iteration

- **[Working with JSON in Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/nosql/query/working-with-json)**
  JSON query functions and operators

### Cosmos DB Key Concepts

- **[Partitioning and horizontal scaling](https://learn.microsoft.com/azure/cosmos-db/partitioning-overview)**
  Choosing the right partition key (critical design decision)

- **[Request Units (RU/s) in Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/request-units)**
  Understanding throughput provisioning and billing

- **[Consistency levels in Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/consistency-levels)**
  Strong, bounded staleness, session, consistent prefix, eventual

- **[Change feed in Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/change-feed)**
  Event-driven architectures and CQRS read model projections

### Performance & Optimization

- **[Optimize request costs in Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/optimize-cost-reads-writes)**
  Query optimization, indexing policies, batch operations

- **[Indexing policies in Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/index-policy)**
  Include/exclude paths, composite indexes, spatial indexes

- **[Bulk operations in Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/nosql/tutorial-dotnet-bulk-import)**
  High-throughput data ingestion patterns

### Advanced Patterns

- **[Modeling data in Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/modeling-data)**
  Embedding vs. referencing, denormalization strategies

- **[Transactions in Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/nosql/transactional-batch)**
  Multi-document transactions within a partition

- **[Global distribution with Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/distribute-data-globally)**
  Multi-region writes, conflict resolution, failover

---

## Azure Table Storage

### Core Documentation

- **[What is Azure Table Storage?](https://learn.microsoft.com/azure/storage/tables/table-storage-overview)**
  Overview of NoSQL key-value storage

- **[Quickstart: Azure Table Storage with .NET](https://learn.microsoft.com/azure/storage/tables/table-storage-quickstart-portal)**
  Getting started with Azure.Data.Tables SDK

- **[Design scalable and performant tables](https://learn.microsoft.com/azure/storage/tables/table-storage-design)**
  Partition key and row key design patterns

### Table Storage Patterns

- **[Designing for querying](https://learn.microsoft.com/azure/storage/tables/table-storage-design-for-query)**
  Efficient query patterns, secondary indexes, table scans

- **[Designing for data modification](https://learn.microsoft.com/azure/storage/tables/table-storage-design-for-modification)**
  Batch operations, entity group transactions

- **[Table design patterns](https://learn.microsoft.com/azure/storage/tables/table-storage-design-patterns)**
  Index table pattern, log tail pattern, high volume delete

### Integration

- **[Azure Table Storage bindings for Azure Functions](https://learn.microsoft.com/azure/azure-functions/functions-bindings-storage-table)**
  Serverless CRUD operations with Functions

---

## Azure Cache for Redis

### Core Documentation

- **[What is Azure Cache for Redis?](https://learn.microsoft.com/azure/azure-cache-for-redis/cache-overview)**
  Overview of managed Redis service

- **[Quickstart: Use Azure Cache for Redis in .NET](https://learn.microsoft.com/azure/azure-cache-for-redis/cache-dotnet-how-to-use-azure-redis-cache)**
  StackExchange.Redis connection patterns

- **[Best practices for Azure Cache for Redis](https://learn.microsoft.com/azure/azure-cache-for-redis/cache-best-practices)**
  Connection pooling, key expiration, memory management

### ASP.NET Core Integration

- **[Distributed caching in ASP.NET Core](https://learn.microsoft.com/aspnet/core/performance/caching/distributed)**
  IDistributedCache abstraction with Redis backend

- **[Response caching in ASP.NET Core](https://learn.microsoft.com/aspnet/core/performance/caching/response)**
  HTTP response caching with Redis

- **[Output caching in ASP.NET Core](https://learn.microsoft.com/aspnet/core/performance/caching/output)**
  Output caching middleware (ASP.NET Core 7+)

### Redis Patterns

- **[Redis data structures](https://redis.io/docs/data-types/)**
  Strings, hashes, lists, sets, sorted sets, streams

- **[Redis transactions](https://redis.io/docs/manual/transactions/)**
  MULTI/EXEC for atomic operations

- **[Redis Pub/Sub](https://redis.io/docs/manual/pubsub/)**
  Lightweight pub/sub messaging (SignalR backplane)

---

## Cross-Database Concerns

### Authentication & Security

- **[Use Azure Active Directory authentication](https://learn.microsoft.com/azure/azure-sql/database/authentication-aad-overview)**
  Managed identity for SQL Database, Cosmos DB, Storage

- **[Customer-managed keys in Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/how-to-setup-cmk)**
  Encryption at rest with Azure Key Vault

- **[Network security for Azure databases](https://learn.microsoft.com/azure/azure-sql/database/network-access-controls-overview)**
  Private endpoints, firewall rules, service endpoints

### Monitoring & Observability

- **[Monitor Azure SQL Database with Azure Monitor](https://learn.microsoft.com/azure/azure-sql/database/monitoring-sql-database-azure-monitor)**
  Metrics, logs, query performance insights

- **[Monitor Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/monitor-cosmos-db)**
  RU consumption, throttling, latency metrics

- **[Application Insights dependency tracking](https://learn.microsoft.com/azure/azure-monitor/app/asp-net-dependencies)**
  Automatic database call telemetry

### Disaster Recovery & High Availability

- **[Business continuity in Azure SQL Database](https://learn.microsoft.com/azure/azure-sql/database/business-continuity-high-availability-disaster-recover-hadr-overview)**
  Automated backups, geo-replication, failover groups

- **[High availability in Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/high-availability)**
  Zone redundancy, multi-region replication, SLA details

- **[Backup and restore in Azure Database for PostgreSQL](https://learn.microsoft.com/azure/postgresql/flexible-server/concepts-backup-restore)**
  Automated backups and point-in-time restore

### Migration Strategies

- **[Azure Database Migration Service](https://learn.microsoft.com/azure/dms/dms-overview)**
  Migrate from on-premises SQL Server, PostgreSQL, MySQL

- **[Migrate to Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/migration/)**
  Data migration tools and strategies

- **[Offline migration to Azure SQL Database](https://learn.microsoft.com/azure/azure-sql/migration-guides/database/sql-server-to-sql-database-guide)**
  Step-by-step migration guide from SQL Server

---

## Decision Guidance

### Choosing Your Database

- **[Choose the right data store](https://learn.microsoft.com/azure/architecture/guide/technology-choices/data-store-overview)**
  Azure Architecture Center decision tree

- **[Compare database options in Azure](https://learn.microsoft.com/azure/architecture/guide/technology-choices/data-store-comparison)**
  Feature matrix: SQL, PostgreSQL, Cosmos DB, Table Storage

- **[Polyglot persistence](https://learn.microsoft.com/azure/architecture/guide/design-principles/use-the-best-data-store)**
  Use multiple databases for different bounded contexts

### Architecture Patterns

- **[CQRS pattern with Cosmos DB](https://learn.microsoft.com/azure/architecture/patterns/cqrs)**
  Command-query separation with multiple data stores

- **[Event sourcing pattern](https://learn.microsoft.com/azure/architecture/patterns/event-sourcing)**
  Using Cosmos DB or Event Hubs as event store

- **[Materialized view pattern](https://learn.microsoft.com/azure/architecture/patterns/materialized-view)**
  Precompute aggregations for read-heavy workloads

- **[Sharding pattern](https://learn.microsoft.com/azure/architecture/patterns/sharding)**
  Horizontal partitioning for scale-out

---

## Related Skills

- **[skill-architecture-patterns](../../skill-architecture-patterns/)** – System architecture influences database choices (microservices → polyglot persistence)
- **[skill-data-platform-selection](../../../data/skills/skill-data-platform-selection/)** – Analytics databases (Synapse, Databricks) vs transactional databases
- **[skill-cqrs-event-sourcing](../../skill-cqrs-event-sourcing/)** – Cosmos DB change feed for CQRS read models
