---
name: skill-data-platform-selection
description: Choose analytics platform (Microsoft Fabric, Azure Databricks, Synapse Analytics, Data Lake) and data architecture (lakehouse, data warehouse, data lake). Use when selecting OLTP vs OLAP database, implementing medallion architecture (bronze/silver/gold), scaling from GB to PB, or migrating on-premises data platform to cloud. Foundational decision affecting all data workloads.
---

# Data Platform Selection

## When to Use This Skill

Use this skill when making decisions about **data platform architecture** for applications, because the wrong choice creates technical debt, cost overruns, and performance bottlenecks:

- **Choosing between relational (SQL) and NoSQL databases** → Data model, query patterns, and consistency requirements dictate platform; wrong choice forces painful migrations
- **Selecting OLTP (transactional) vs OLAP (analytical) vs hybrid workloads** → OLTP needs low-latency writes with ACID; OLAP needs MPP with columnar storage; mixing hurts both
- **Architecting for global distribution with low latency** → Cosmos DB multi-region write, SQL geo-replication, or edge caching strategies differ in cost and complexity
- **Scaling from gigabytes to petabytes** → Single-node databases (Azure SQL) hit limits at terabytes; data lakes/warehouses (Synapse, Databricks) scale horizontally
- **Migrating from on-premises databases to cloud-native platforms** → Lift-and-shift (SQL MI) vs re-architect (Cosmos DB, Synapse) vs hybrid (PostgreSQL) have different ROI timelines
- **Implementing real-time analytics on streaming data** → Batch (Data Factory) vs streaming (Databricks, Stream Analytics) vs hybrid (Lambda architecture) tradeoffs
- **Balancing cost vs performance for workloads** → Serverless (pay-per-query) vs provisioned (reserved capacity) vs spot instances; DTU vs vCore pricing models

## Decision Framework

```text
What's your data platform need?

├─ OLTP transactional workload with ACID?
│  ├─ Relational schema required?
│  │  └─ Azure SQL Database (managed, vCore tiers, Hyperscale for 100TB)
│  └─ Flexible schema or global distribution?
│     └─ Cosmos DB for NoSQL (multi-region write, 99.999% SLA)
│
├─ OLAP data warehouse for analytics?
│  ├─ Structured data with SQL queries?
│  │  └─ Synapse Analytics Dedicated SQL Pool (MPP, columnar, petabyte scale)
│  └─ Semi-structured or unstructured data?
│     └─ Data Lake Storage Gen2 + Databricks (Spark, Delta Lake)
│
├─ Real-time streaming analytics?
│  └─ Databricks Structured Streaming or Azure Stream Analytics (Event Hubs ingestion)
│
├─ Open-source with hybrid relational+NoSQL?
│  └─ PostgreSQL with JSONB (Azure Database for PostgreSQL Flexible Server)
│
└─ ETL/ELT orchestration?
   └─ Azure Data Factory (managed pipelines, 90+ connectors)
```

## Scoring Model

Use this as a **conversation starter** to evaluate data platforms against your specific requirements:

| Factor            | Azure SQL               | Cosmos DB                  | Synapse (Dedicated Pool)  | Data Lake + Databricks             | PostgreSQL                | Data Factory                  |
| ----------------- | ----------------------- | -------------------------- | ------------------------- | ---------------------------------- | ------------------------- | ----------------------------- |
| **Workload Type** | OLTP (transactional)    | OLTP (NoSQL)               | OLAP (analytics)          | Analytics (big data)               | OLTP/OLAP hybrid          | ETL/ELT                       |
| **Data Model**    | Relational (tables, FK) | NoSQL (JSON documents)     | Relational (star schema)  | Schema-on-read (Parquet, Delta)    | Relational + JSONB        | N/A (orchestration)           |
| **Scale Limit**   | 100TB (Hyperscale)      | Unlimited (auto-partition) | 240 nodes (petabytes)     | Petabytes+ (object storage)        | 64TB (single server)      | N/A                           |
| **Query Latency** | ms (indexed)            | ms (single-partition)      | seconds (MPP, columnar)   | seconds-minutes (Spark)            | ms (indexed)              | Minutes-hours (batch)         |
| **Consistency**   | Strong (ACID)           | Tunable (5 levels)         | Strong (SQL txn)          | Eventual (Delta for ACID)          | Strong (ACID)             | N/A                           |
| **Cost Model**    | vCore or DTU (per hour) | RU/s (per request unit)    | DWU (compute + storage)   | Compute (Databricks DBU) + Storage | vCore (per hour)          | Pipeline runs + DIU hours     |
| **Best For**      | Line-of-business apps   | Global apps, IoT telemetry | Enterprise data warehouse | Data science, ML, lakehouse        | Migration from PostgreSQL | Data movement, transformation |

## Data Platform Patterns

### 1. Azure SQL Database (Managed Relational OLTP)

**What**: Fully managed SQL Server engine for transactional workloads with ACID guarantees and relational integrity.

**How it works**: Provision database with vCore (4-80 vCores) or DTU tiers (10-4000 DTUs). Automatic backups (7-35 days), point-in-time restore. Active geo-replication for secondary regions (read replicas). Elastic pools for multi-tenant SaaS (share resources across databases). Hyperscale tier for 100TB single database with instant scale-out.

**When to use**: Traditional line-of-business applications requiring ACID transactions, referential integrity (foreign keys), stored procedures, and complex SQL queries. Example: E-commerce order processing with inventory management requiring strong consistency across orders, payments, and stock levels.

**Considerations**: Vertical scaling (increase vCores) has brief downtime (seconds). Horizontal scaling requires sharding (manual or Elastic Database Tools). Cost increases linearly with vCores (~$300/mo for 4 vCores General Purpose). Hyperscale tier optimized for read-heavy workloads (4 read replicas included).

### 2. Azure Cosmos DB (Global NoSQL Multi-Model)

**What**: Globally distributed NoSQL database with turnkey multi-region replication and tunable consistency.

**How it works**: Partition data by partition key (e.g., customerId, region) for horizontal scaling. Choose consistency level (Strong, Bounded Staleness, Session, Consistent Prefix, Eventual). Pay per Request Unit (RU/s): 1 RU = read 1KB item by ID. Multi-region write for active-active (write to nearest region, replicate globally with <10ms). APIs: NoSQL (native), MongoDB, Cassandra, Gremlin (graph), Table Storage.

**When to use**: Global applications requiring low latency (<10ms P99) in multiple regions, or unpredictable scale (auto-scale RU/s from 400 to 1M+). Example: Gaming leaderboard with 10M+ users across continents, writing scores locally with eventual consistency for global ranking.

**Considerations**: Query cost (RU/s) increases with cross-partition queries (avoid "SELECT \* FROM c"). Partition key choice critical (hot partitions cause throttling). Cost can spike with inefficient queries (~$0.008 per 10K RU/s-hour). Strong consistency with multi-region increases latency (RTT between regions).

### 3. Azure Synapse Analytics Dedicated SQL Pool (Data Warehouse)

**What**: Massively parallel processing (MPP) data warehouse for OLAP queries on structured data (petabyte scale).

**How it works**: Data distributed across 60 compute nodes (distributions) using hash distribution (join optimization) or round-robin (load speed). Columnar storage (clustered columnstore index) compresses data 10x, scans only queried columns. Scale compute independently of storage (pause compute when idle, pay only storage). Partitioning for lifecycle management (archive old data by switching partitions).

**When to use**: Enterprise data warehouse with complex SQL queries (joins, aggregations) on billions of rows. Example: Retail analytics joining 5 years of sales transactions (10B rows) with products (1M rows) and customers (100M rows) for monthly executive reports.

**Considerations**: Cost optimized for infrequent, complex queries (not real-time OLTP). Compute billed per DWU hour (DW1000c = 10 nodes = ~$1.20/hour). Ingestion best with PolyBase (parallel load from Data Lake). Replicate small dimension tables to all nodes (avoid shuffling during joins).

### 4. Azure Data Lake Storage Gen2 + Databricks (Big Data Analytics)

**What**: Hierarchical data lake (bronze/silver/gold layers) with Databricks Spark for batch and streaming analytics.

**How it works**: Store raw data (CSV, JSON, logs) in bronze layer. Transform to curated Parquet in silver (partitioned by date). Aggregate to business-ready Delta tables in gold. Databricks notebooks (Python, Scala, SQL) run Spark jobs on clusters (2-1000+ nodes). Delta Lake adds ACID transactions, time travel, and schema enforcement to data lake files.

**When to use**: Big data analytics with semi-structured or unstructured data, data science workflows, or machine learning pipelines. Example: Log analytics processing 10TB/day of application logs, joining with customer data, training ML models for anomaly detection.

**Considerations**: Storage cost low (~$0.02/GB/month for hot tier), but Databricks compute cost high (DBU = Databricks Unit, ~$0.07-0.55/DBU-hour depending on cluster type). Optimize with auto-scaling clusters (terminate when idle). Use Delta Lake for UPSERT (merge) and time travel (query historical versions).

### 5. Azure Database for PostgreSQL (Open-Source Relational)

**What**: Managed PostgreSQL with Azure integrations, supporting relational + NoSQL hybrid (JSONB columns).

**How it works**: Flexible Server deployment with zone-redundant high availability (automatic failover <120s). Scale vertically (2-96 vCores) or horizontally (read replicas for read-heavy workloads). JSONB columns for flexible schema (index with GIN for fast queries). Extensions: PostGIS (geospatial), pg_stat_statements (query tuning), pgvector (vector search).

**When to use**: Migrating from on-premises PostgreSQL, or requiring hybrid relational/document model. Example: SaaS application with core relational schema (users, subscriptions) plus flexible tenant-specific attributes (JSONB column for custom fields).

**Considerations**: Lower cost than Azure SQL (~$50/mo for 2 vCores vs ~$200/mo SQL). No automatic tuning (Azure SQL has intelligent insights). Limited to 64TB (vs 100TB Hyperscale SQL). Citus extension for horizontal sharding (distributed PostgreSQL) for 100TB+ scale.

### 6. Azure Data Factory (ETL/ELT Orchestration)

**What**: Cloud-native data integration service for building ETL/ELT pipelines without code or with code (Python, .NET).

**How it works**: 90+ connectors for moving data (SQL, Cosmos DB, Data Lake, Snowflake, Salesforce). Copy activity for bulk data movement (parallelized, incremental loads with watermarks). Mapping data flows for visual transformation (joins, aggregations, derived columns). Triggers for scheduling (time-based, event-based on blob storage). Linked services with managed identity authentication (no credentials).

**When to use**: Data movement and transformation between systems, incremental loads (CDC-like), or orchestrating Databricks/Synapse jobs. Example: Nightly ETL loading 1M rows from on-premises SQL Server to Synapse, transforming in mapping data flow, triggering Databricks ML pipeline.

**Considerations**: Cost per pipeline run (first 1K runs free, then $1 per 1K runs) plus Data Integration Units (DIU-hours, ~$0.25/DIU-hour for 4 DIU). Use incremental copy pattern to avoid full reloads. Mapping data flows run on Spark (more expensive than basic copy). Consider Synapse Pipelines (same engine, integrated with Synapse).

## Quick Reference

| Use Case                                     | Recommended Platform        | Notes                                                 |
| -------------------------------------------- | --------------------------- | ----------------------------------------------------- |
| E-commerce orders (ACID transactions)        | Azure SQL Database          | Relational integrity, ACID, <10ms latency             |
| Global IoT telemetry (100M devices)          | Cosmos DB for NoSQL         | Multi-region write, auto-scale, partition by deviceId |
| Enterprise data warehouse (BI reports)       | Synapse Dedicated SQL Pool  | MPP, columnar, star schema, complex SQL               |
| Data science on big data (logs, clickstream) | Data Lake Gen2 + Databricks | Parquet/Delta, Spark, ML, petabyte scale              |
| SaaS with flexible schema per tenant         | PostgreSQL with JSONB       | Relational core + flexible attributes                 |
| ETL between systems (on-prem to cloud)       | Azure Data Factory          | 90+ connectors, incremental loads, orchestration      |

## Common Pitfalls

- **Using OLTP database for analytics (or vice versa)** → Azure SQL degrades under full table scans for BI queries (no columnstore indexes). Synapse has high latency for single-row lookups (MPP overhead). Separate OLTP (SQL/Cosmos) from OLAP (Synapse/Databricks) with Data Factory pipelines.

- **Ignoring partition key in Cosmos DB** → Choosing wrong partition key (low cardinality like "country" with 100 values) creates hot partitions (throttling). Use high-cardinality key (e.g., userId, orderId). Cross-partition queries cost 10-100x more RU/s than single-partition.

- **Over-provisioning Synapse Dedicated Pool** → DW1000c (~$1.20/hour = $8,640/month) overkill for dev/test. Use DW100c (~$1.20/day) or pause when idle (pay only storage ~$120/TB/year). Or use Serverless SQL Pool for ad-hoc queries (pay per TB scanned).

- **Not compressing data in Data Lake** → Uncompressed CSV takes 10x storage vs Parquet with Snappy. Example: 1TB CSV → 100GB Parquet = $20/mo vs $2/mo storage cost. Use Parquet or Delta in silver/gold layers.

- **Mixing batch and real-time workloads incorrectly** → Data Factory runs hourly/daily (batch). For <1 min latency, use Databricks Structured Streaming or Azure Stream Analytics. Lambda architecture: streaming for real-time dashboard, batch for historical reporting.

- **Ignoring data residency and sovereignty** → Cosmos DB and Synapse store data in specified Azure regions, but backups replicate to paired region (e.g., EU West → EU North). For regulations (GDPR, HIPAA), verify backup location and disable geo-redundancy if needed.

## Bundled Resources

- **Code Examples**: See `references/code-examples.md` for working implementations of each data platform (Azure SQL, Cosmos DB, Synapse, Data Lake + Databricks, PostgreSQL, Data Factory) with connection patterns, queries, and transformations.
- **Microsoft Learn**: See `references/microsoft-learn.md` for curated documentation on Azure data services decision trees, architecture patterns, OLTP vs OLAP design, and cost optimization strategies.
