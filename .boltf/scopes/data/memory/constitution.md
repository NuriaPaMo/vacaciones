# BOLT Framework Project Constitution — Scope: Data (Analytics)

> **Extracted from**: `.boltf/memory/constitution.md`
> **Scope**: `data` — Analytical data architectures, data platforms, ETL/ELT orchestration, and data governance.
> **Focus**: Modern data analytics patterns (Medallion, Lakehouse, Data Warehousing, Big Data)
> **Excludes**: Transactional databases (see `backend` scope), Infrastructure/DevOps (see `cloud-platform` scope)
> Articles marked with 🔄 are **common to all scopes** and always present.

---

## Preamble 🔄

This Constitution establishes the governing principles, technology decisions, and standards for the **[PROJECT_NAME]** project. All AI agents, developers, and automated systems MUST adhere to this document.

**This document is the SINGLE SOURCE OF TRUTH.**

**Cloud Provider**: Microsoft Azure (mandatory for all deployments)

---

## Article V: Analytical Data Platform Strategy

> **📋 Applies to**: Data & Analytics projects
> **⏭️ Skip if**: Purely transactional apps (use `backend` scope)

### Section 5.1: Primary Analytics Platform 🔴 CRITICAL

> **🔴 CRITICAL**: Analytics platform (Fabric vs Databricks vs Synapse) = fundamentally different ecosystems

Select ONE primary platform:

- [ ] **Microsoft Fabric** - Unified SaaS analytics (Lakehouse, Warehouse, Real-Time Intelligence, Data Factory, Power BI)
- [ ] **Azure Databricks** - Apache Spark-based analytics, Delta Lake, Unity Catalog
- [ ] **Azure Synapse Analytics** - Enterprise data warehouse, Spark pools, serverless SQL
- [ ] **Hybrid** - Combination of above (specify integration strategy)

**Platform Justification**: [Explain why the selected platform meets analytical requirements]

**Key Platform Capabilities**:

| Capability             | Fabric              | Databricks              | Synapse                 |
| ---------------------- | ------------------- | ----------------------- | ----------------------- |
| Lakehouse (Delta Lake) | ✅ Native           | ✅ Native               | ✅ Via Spark            |
| Data Warehouse         | ✅ SQL Warehouse    | ⚠️ SQL Warehouses       | ✅ Dedicated/Serverless |
| Spark Processing       | ✅ Managed          | ✅ Optimized            | ✅ Spark Pools          |
| Real-Time Analytics    | ✅ Eventstreams/KQL | ✅ Structured Streaming | ✅ Stream Analytics     |
| Data Orchestration     | ✅ Pipelines        | ✅ Workflows            | ✅ Pipelines            |
| Unified Governance     | ✅ Purview + Fabric | ✅ Unity Catalog        | ✅ Purview              |

### Section 5.2: Data Storage Architecture Pattern 🔴 CRITICAL

> **🔴 CRITICAL**: Architecture pattern (Lakehouse vs Warehouse vs Medallion) = different data modeling approaches

Select primary architectural pattern:

- [ ] **Lakehouse** - Unified architecture combining data lake storage + warehouse analytics capabilities (Delta Lake format)
- [ ] **Data Warehouse** - Traditional dimensional modeling (star/snowflake schemas), optimized for BI queries
- [ ] **Data Lake** - Raw storage optimized for batch/stream ingestion, schema-on-read
- [ ] **Lambda Architecture** - Separate batch (cold path) + real-time (hot path) processing layers
- [ ] **Medallion Architecture** - Progressive layers: Bronze (raw) → Silver (validated) → Gold (curated)

**Pattern Justification**: [Explain pattern selection based on workload characteristics, data volume, latency requirements]

**Recommended**: Medallion architecture within a Lakehouse for modern cloud-native analytics

### Section 5.3: Storage Format & Optimization 🟡 IMPORTANT

> **🟡 IMPORTANT**: Storage format affects performance and features but can be migrated

#### Data Format

Select primary format for analytical tables:

- [ ] **Delta Lake** - ACID transactions, time travel, schema enforcement, DML support (recommended)
- [ ] **Apache Iceberg** - Open table format with schema/partition evolution
- [ ] **Apache Hudi** - Incremental data processing, record-level updates
- [ ] **Parquet** - Columnar format for read-heavy analytical queries (no transactions)
- [ ] **CSV/JSON** - Raw data only (Bronze layer ingestion)

**Format Justification**: Delta Lake recommended for ACID guarantees and ecosystem support

#### Compression 🟢 LOW-PRIO

> **🟢 LOW-PRIO**: Compression can be changed per table without architectural impact

- [ ] **Zstandard (zstd)** - Better compression ratio for cold/archival data (~30-40% better than Snappy)
- [ ] **Snappy** - Faster decompression for frequently accessed hot data

#### Partitioning Strategy 🟡 IMPORTANT

> **🟡 IMPORTANT**: Partitioning affects query performance but can be re-organized

- [ ] **Date-based** - `/year=YYYY/month=MM/day=DD` (most common for time-series data)
- [ ] **Tenant/Customer-based** - `/tenant_id=X/` (multi-tenant architectures)
- [ ] **Hybrid** - Combination of date + domain (e.g., `/tenant=X/year=YYYY/month=MM`)
- [ ] **Hash-based** - Distribute data evenly across partitions

**Partition Key**: [Specify partition columns]
**Partition Size**: Target ~[N] GB per partition (1-10 GB recommended)

---

## Article VI: Medallion Architecture Implementation

> **📋 Applies to**: Data Engineering, Lakehouse-based projects
> **⏭️ Skip if**: Using traditional data warehouse only (no multi-layer design)

**Medallion Architecture Overview**: A multi-layered data architecture pattern that incrementally improves data quality and structure as data flows from raw ingestion (Bronze) → validated/enriched (Silver) →business-ready (Gold).

### Section 6.1: Bronze Layer (Raw Zone) 🟡 IMPORTANT

> **🟡 IMPORTANT**: Bronze layer strategy affects data lineage and reprocessing capabilities

**Purpose**: Preserve raw data in original format as single source of truth for data lineage and reprocessing

**Storage Location**: `/{lakehouse_or_storage}/bronze/{source_system}/{table_or_topic}/`

**Characteristics**:

- [ ] **Minimal transformation** - Schema-on-read, preserve original structure
- [ ] **All data types supported** - Structured (tables), semi-structured (JSON, XML), unstructured (files, images)
- [ ] **Append-only ingestion** - No updates or deletes (immutable audit trail)
- [ ] **Retain full history** - Enable reprocessing if Silver/Gold logic changes
- [ ] **Schema flexibility** - Store as `string` or `binary` to protect against unexpected schema changes
- [ ] **Metadata enrichment** - Add ingestion timestamp, source system, batch ID

**Data Retention**: \_\_\_ days/months/years (or indefinite for compliance)

**Table Naming Convention**: `bronze_{source_system}_{table_name}_raw`

**Example Bronze Ingestion**:

```python
# Databricks/Fabric Bronze ingestion example
raw_df = spark.read.format("csv").load("s3://source/sales.csv")

bronze_df = raw_df \
    .withColumn("_ingestion_timestamp", current_timestamp()) \
    .withColumn("_source_file", input_file_name()) \
    .withColumn("_batch_id", lit(batch_id))

bronze_df.write.format("delta") \
    .mode("append") \
    .partitionBy("year", "month", "day") \
    .save("/bronze/erp/sales/")
```

### Section 6.2: Silver Layer (Validated & Enriched) 🟡 IMPORTANT

> **🟡 IMPORTANT**: Silver transformations define data quality standards

**Purpose**: Cleaned, validated, deduplicated, and enriched data optimized for analytics workloads

**Storage Location**: `/{lakehouse_or_storage}/silver/{domain}/{entity}/`

**Transformations Applied**:

- [ ] **Data quality checks** - Null handling, type validation, range checks
- [ ] **Deduplication** - Remove duplicate records based on business keys
- [ ] **Schema enforcement** - Standardize column names, data types (Bronze strings → proper types)
- [ ] **PII masking/anonymization** - Apply privacy policies (GDPR, HIPAA)
- [ ] **Business logic enrichment** - Calculate derived fields, apply business rules
- [ ] **Joins across sources** - Integrate data from multiple Bronze sources
- [ ] **Slowly Changing Dimensions (SCD)** - Track historical changes (Type 1, 2, or 3)

**Modeling Approach**:

- [ ] **Third Normal Form (3NF)** - Normalized data warehouse, reduce redundancy
- [ ] **Data Vault 2.0** - Hub-Link-Satellite pattern for agile data warehousing
- [ ] **Wide tables** - Denormalized for query performance (pre-joined dimensions)

**Data Retention**: \_\_\_ days/months/years

**Table Naming Convention**: `silver_{domain}_{entity}`

**Example Silver Transformation**:

```sql
-- Databricks/Fabric Silver transformation example
CREATE OR REPLACE TABLE silver_sales_orders AS
SELECT
    CAST(order_id AS BIGINT) AS order_id,
    CAST(customer_id AS BIGINT) AS customer_id,
    TO_DATE(order_date, 'yyyy-MM-dd') AS order_date,
    CAST(amount AS DECIMAL(18,2)) AS order_amount,
    UPPER(status) AS order_status,
    CURRENT_TIMESTAMP() AS processed_timestamp
FROM bronze_erp_sales_raw
WHERE order_id IS NOT NULL  -- Data quality filter
  AND amount > 0            -- Business rule validation
QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY _ingestion_timestamp DESC) = 1; -- Deduplication
```

### Section 6.3: Gold Layer (Business-Ready) 🟢 LOW-PRIO

> **🟢 LOW-PRIO**: Gold layer design can evolve based on BI requirements

**Purpose**: Highly curated, aggregated data optimized for business consumption and BI reporting

**Storage Location**: `/{lakehouse_or_storage}/gold/{business_area}/{mart}/`

**Characteristics**:

- [ ] **Dimensional modeling** - Star/snowflake schemas (Fact + Dimension tables)
- [ ] **Pre-aggregated metrics** - Daily/weekly/monthly aggregations
- [ ] **Subject-area data marts** - Sales, Finance, Operations, Customer
- [ ] **Optimized for BI tools** - Power BI, Tableau Direct Query/Direct Lake
- [ ] **Fewer tables** - Simplified, business-friendly schemas
- [ ] **Business-friendly naming** - `DimCustomer`, `FactSales`, `MonthlySalesAggregate`

**Optimization Techniques**:

- [ ] **Z-Ordering** (Delta Lake) - Co-locate related data for filter optimization
- [ ] **Materialized Views** - Pre-computed aggregations for faster queries
- [ ] **Indexing** - Bloom filters (Delta Lake), statistics collection
- [ ] **Result Caching** - Cache frequently run queries

**Data Retention**: \_\_\_ months/years (longer retention for historical reporting)

**Table Naming Convention**:

- `dim_{entity}` for dimensions
- `fact_{entity}` for facts
- `agg_{entity}_{grain}` for aggregates

**Example Gold Layer**:

```sql
-- Dimensional model: Fact Sales
CREATE OR REPLACE TABLE gold_sales_fact_sales AS
SELECT
    s.order_id,
    s.customer_id,
    s.product_id,
    s.order_date,
    s.order_amount,
    s.quantity,
    s.discount_amount,
    s.order_amount - s.discount_amount AS net_amount
FROM silver_sales_orders s
WHERE s.order_status = 'COMPLETED';

-- Pre-aggregated metric: Monthly Sales by Customer
CREATE OR REPLACE TABLE gold_sales_agg_monthly_customer AS
SELECT
    customer_id,
    DATE_TRUNC('month', order_date) AS month,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(net_amount) AS total_revenue,
    AVG(net_amount) AS avg_order_value
FROM gold_sales_fact_sales
GROUP BY customer_id, DATE_TRUNC('month', order_date);
```

---

## Article VII: Data Integration & Orchestration

> **📋 Applies to**: Data Engineering, ETL/ELT pipelines
> **⏭️ Skip if**: No data ingestion/transformation requirements

### Section 7.1: Integration Platform

Select ONE primary orchestration platform:

- [ ] **Azure Data Factory (ADF)** - Enterprise ETL/ELT, 90+ connectors, hybrid integration
- [ ] **Microsoft Fabric Data Pipelines** - Unified Fabric experience, SaaS-native
- [ ] **Azure Databricks Workflows** - Spark-native orchestration (Jobs, DLT pipelines)
- [ ] **Synapse Pipelines** - Integrated with Synapse Analytics (similar to ADF)

**Platform Justification**: [Explain why this platform meets integration requirements]

### Section 7.2: Integration Pattern

Select primary pattern:

- [ ] **ETL (Extract-Transform-Load)** - Transform data using separate engine (ADF Data Flows, Spark) before loading
- [ ] **ELT (Extract-Load-Transform)** - Load raw data first, transform using target system compute (Spark, SQL)
- [ ] **Hybrid** - ETL for sensitive/cleansing operations, ELT for bulk transformations

**Pattern Justification**: ELT is recommended for cloud-native platforms with elastic compute (Databricks, Fabric, Synapse)

**Why ELT for Modern Analytics**:

- ✅ Leverage elastic compute of Lakehouse/Warehouse
- ✅ Preserve raw data for auditing/reprocessing
- ✅ Schema evolution flexibility
- ✅ Better performance for large-scale transformations

### Section 7.3: Data Ingestion Strategy

#### Batch Ingestion

| Source System Type | Connector/Tool     | Frequency        | Incremental Load | Change Data Capture (CDC) |
| ------------------ | ------------------ | ---------------- | ---------------- | ------------------------- |
| Azure SQL Database | [ ] ADF [ ] Fabric | [ ] Hourly/Daily | [ ] Yes [ ] No   | [ ] Yes [ ] No            |
| On-premises SQL    | [ ] Self-hosted IR | [ ] Hourly/Daily | [ ] Yes [ ] No   | [ ] Yes [ ] No            |
| REST APIs          | [ ] ADF [ ] Custom | [ ] Hourly/Daily | [ ] Yes [ ] No   | N/A                       |
| File storage (CSV) | [ ] ADF [ ] Fabric | [ ] Hourly/Daily | [ ] Yes [ ] No   | N/A                       |
| SaaS (Salesforce)  | [ ] ADF [ ] Fabric | [ ] Hourly/Daily | [ ] Yes [ ] No   | [ ] Yes [ ] No            |

**Incremental Load Strategy**:

- [ ] **Watermark-based** - Track last processed timestamp/ID
- [ ] **Change Data Capture (CDC)** - Capture inserts/updates/deletes from source logs
- [ ] **Delta/Incremental files** - Process only new/changed files

#### Streaming Ingestion

- [ ] **Azure Event Hubs** - High-throughput event streaming (millions events/sec)
- [ ] **Azure IoT Hub** - IoT device telemetry and command/control
- [ ] **Apache Kafka** - Open-source event streaming platform
- [ ] **Databricks Structured Streaming** - Spark-based stream processing
- [ ] **Fabric Eventstreams** - SaaS real-time intelligence, KQL-based

**Streaming Use Cases**: Real-time dashboards, fraud detection, IoT telemetry, clickstream analytics

### Section 7.4: Transformation Engine

Select transformation approach based on workload:

#### For Batch Transformations

- [ ] **Azure Data Factory Data Flows** - Visual, low-code transformations (GUI-based)
- [ ] **Databricks Notebooks** - Code-first PySpark/Scala/SQL (full flexibility)
- [ ] **Synapse Spark Pools** - Managed Spark for big data processing
- [ ] **T-SQL Scripts** - SQL-based transformations in Warehouse/SQL Pools
- [ ] **Fabric Dataflows Gen2** - Power Query-based transformations (no-code)
- [ ] **Databricks Delta Live Tables (DLT)** - Declarative ETL pipelines with data quality

**Transformation Tool Selection**:

- Use **Data Flows/Dataflows Gen2** for citizen data engineers (low-code)
- Use **Databricks Notebooks** for complex logic, ML feature engineering
- Use **SQL Scripts** for set-based operations close to data

#### For Streaming Transformations

- [ ] **Databricks Structured Streaming** - Micro-batch streaming, exactly-once semantics
- [ ] **Fabric Real-Time Intelligence** - KQL-based streaming analytics
- [ ] **Synapse Spark Streaming** - Managed Spark Streaming
- [ ] **Azure Stream Analytics** - SQL-based streaming (limited to simple transformations)

### Section 7.5: Orchestration & Scheduling

**Trigger Types**:

- [ ] **Schedule-based** - Cron expressions (hourly, daily, weekly)
- [ ] **Event-driven** - File arrival in Blob Storage, Eventstream message
- [ ] **Manual** - On-demand execution for ad-hoc runs
- [ ] **Dependency-based** - After upstream pipeline/job completes (tumbling window)

**Pipeline Dependencies**:

- [ ] **Sequential** - Pipeline B runs only after Pipeline A succeeds
- [ ] **Parallel** - Multiple pipelines run simultaneously
- [ ] **Conditional** - Run based on pipeline output (success/failure branches)

**Error Handling & Resilience**:

- [ ] **Retry Policy** - Max retries: \_\_\_, Initial interval: \_\_\_ seconds, Max interval: \_\_\_ seconds
- [ ] **Dead-letter Queue/Quarantine** - Store failed records for manual review
- [ ] **Alerting** - Email/Teams notifications on failure
- [ ] **Exponential Backoff** - Incremental retry delays
- [ ] **Idempotency** - Safe to re-run pipeline without duplicates

**SLA Targets**:

- Bronze ingestion SLA: < \_\_\_ minutes/hours from source
- Silver transformation SLA: < \_\_\_ minutes/hours from Bronze
- Gold curation SLA: < \_\_\_ minutes/hours from Silver

---

## Article VIII: Data Governance & Quality

> **📋 Applies to**: ALL data projects (mandatory for production)
> **⏭️ Skip if**: Prototypes only (NOT recommended, establish governance early)

### Section 8.1: Data Governance Platform

Select ONE or HYBRID:

- [ ] **Microsoft Purview** - Unified data governance, catalog, lineage, sensitivity classification (recommended for Azure-wide governance)
- [ ] **Unity Catalog** - Databricks-native governance, fine-grained access control, centralized metastore
- [ ] **Hybrid** - Purview for discovery/classification + Unity Catalog for Databricks access control

**Governance Capabilities**:

| Capability                 | Purview                 | Unity Catalog         |
| -------------------------- | ----------------------- | --------------------- |
| Data Catalog & Discovery   | ✅ Enterprise-wide      | ✅ Databricks-focused |
| Data Lineage               | ✅ ADF, Synapse, SQL    | ✅ Spark, Delta Lake  |
| Sensitivity Classification | ✅ Auto-classification  | ⚠️ Manual tagging     |
| Access Control (RBAC)      | ⚠️ Read-only catalog    | ✅ Fine-grained ACLs  |
| Data Quality Monitoring    | ✅ Purview Data Quality | ⚠️ Expectations (DLT) |
| Audit Logs                 | ✅ Integrated           | ✅ Unity Catalog logs |

**Recommended Approach**: Use Purview for organization-wide discovery + Unity Catalog for Databricks access control

### Section 8.2: Data Quality Framework

**Data Quality Dimensions** (ISO 8000 standard):

| Dimension        | Check Type                                         | Implementation Tool                    | Threshold  |
| ---------------- | -------------------------------------------------- | -------------------------------------- | ---------- |
| **Accuracy**     | Business rule validation                           | [ ] DLT [ ] ADF [ ] Great Expectations | \_\_% pass |
| **Completeness** | Null/missing value checks                          | [ ] DLT [ ] ADF [ ] Great Expectations | \_\_% pass |
| **Consistency**  | Cross-source reconciliation, referential integrity | [ ] DLT [ ] ADF [ ] Great Expectations | \_\_% pass |
| **Timeliness**   | Data freshness SLA monitoring                      | [ ] ADF [ ] Databricks Alerts          | < \_\_ hrs |
| **Uniqueness**   | Duplicate detection (primary key violations)       | [ ] DLT [ ] ADF [ ] Great Expectations | \_\_% pass |
| **Validity**     | Format/range validation (dates, emails)            | [ ] DLT [ ] ADF [ ] Great Expectations | \_\_% pass |

**Data Quality Actions**:

- [ ] **Quarantine/Reject** - Isolate bad records in `{layer}_quarantine` table for manual review
- [ ] **Auto-fix** - Apply default values/transformations (document in lineage)
- [ ] **Fail Pipeline** - Stop pipeline on quality threshold breach (fail-fast for critical data)
- [ ] **Alert Data Stewards** - Notify via email/Teams when quality degrades

**Data Quality Tools**:

- [ ] **Databricks Delta Live Tables (DLT) Expectations** - Declarative quality checks in pipelines
- [ ] **Azure Data Factory Data Flows** - Built-in data quality transformations
- [ ] **Great Expectations** - Open-source Python library for data validation
- [ ] **Custom Spark Validations** - Code-based quality checks in notebooks

**Example DLT Quality Expectation**:

```python
@dlt.expect_or_fail("valid_order_amount", "order_amount > 0")
@dlt.expect("valid_customer_id", "customer_id IS NOT NULL")
@dlt.table()
def silver_orders():
    return spark.readStream.table("bronze_orders")
```

### Section 8.3: Data Lineage & Impact Analysis

**Lineage Tracking**:

- [ ] **End-to-end lineage** - Source systems → Bronze → Silver → Gold → BI reports/ML models
- [ ] **Column-level lineage** - Track field-level transformations and derivations
- [ ] **Impact analysis** - Identify downstream dependencies before schema/logic changes
- [ ] **Automated lineage capture** - No manual documentation required

**Lineage Tools**:

- [ ] **Microsoft Purview Data Map** - Automated lineage from ADF, Synapse, Power BI, SQL
- [ ] **Unity Catalog Lineage** - Databricks Delta table/column lineage (Spark operations)
- [ ] **OpenLineage** - Open-source lineage standard (integrates with Airflow, Spark)

**Lineage Use Cases**:

- ✅ Regulatory compliance (GDPR Article 30 - Record of Processing Activities)
- ✅ Root cause analysis for data quality issues
- ✅ Impact assessment before schema changes
- ✅ Data discovery for analysts

### Section 8.4: Data Classification & Sensitivity

**Classification Labels** (Microsoft Information Protection):

- [ ] **Public** - No business impact if disclosed
- [ ] **Internal** - Employees/partners only
- [ ] **Confidential** - Restricted access, business impact if disclosed
- [ ] **Highly Confidential** - PII, financial data, regulated data (GDPR, HIPAA)

**PII Handling Strategy**:

- [ ] **Dynamic Data Masking** - Mask PII in Gold layer for non-privileged users
- [ ] **Tokenization** - Replace PII with tokens (preserve referential integrity)
- [ ] **Column-level Encryption** - Azure Always Encrypted for SQL, client-side encryption
- [ ] **Anonymization** - Remove/hash identifiable attributes (irreversible)
- [ ] **Pseudonymization** - Replace identifiers with pseudonyms (reversible with key)

**Data Minimization**:

- [ ] Only ingest PII fields that are absolutely necessary
- [ ] Drop PII from Bronze→Silver if not needed downstream
- [ ] Apply retention policies to automatically delete aged PII

**Example Masking**:

```sql
-- Databricks/Fabric: Mask email for non-admin users
CREATE OR REPLACE VIEW gold_customers_masked AS
SELECT
    customer_id,
    CASE
        WHEN is_member('admins') THEN email
        ELSE REGEXP_REPLACE(email, '(.{2}).*@(.*)', '$1***@$2')
    END AS email,
    phone_number_masked
FROM gold_customers;
```

### Section 8.5: Access Control & Auditing

**Access Control Model**:

- [ ] **Role-Based Access Control (RBAC)** - Assign permissions to roles (DataEngineer, DataAnalyst, DataScientist)
- [ ] **Attribute-Based Access Control (ABAC)** - Dynamic access based on user/data attributes
- [ ] **Row-Level Security (RLS)** - Filter rows based on user context (e.g., tenant isolation)
- [ ] **Column-Level Security** - Restrict access to sensitive columns (e.g., PII masking)
- [ ] **Tag-based Access Control** - Unity Catalog tags for policy-driven access

**Access Control Implementation**:

- [ ] **Unity Catalog** - Fine-grained ACLs (catalog, schema, table, column, row levels)
- [ ] **Fabric Workspace Roles** - Viewer, Contributor, Admin
- [ ] **Synapse SQL RBAC** - Database roles + row-level security
- [ ] **Power BI RLS** - DAX-based row filtering in semantic models

**Audit Logging**:

- [ ] **Unity Catalog Audit Logs** - All data access, permission changes (read/write/delete operations)
- [ ] **Microsoft Purview Audit Logs** - Data governance activity (classification, lineage queries)
- [ ] **Synapse/Fabric Audit Logs** - Platform-level resource access
- [ ] **Integration with SIEM** - [ ] Microsoft Sentinel [ ] Splunk [ ] Custom

**Compliance Reporting**:

- Generate access reports for auditors (who accessed PII, when, why)
- Track data lineage for regulatory compliance (GDPR, HIPAA)
- Monitor unusual access patterns (potential data exfiltration)

---

## Article IX: Performance & Cost Optimization

> **📋 Applies to**: Production data workloads
> **⏭️ Skip if**: Development/POC only

### Section 9.1: Query Performance Optimization

**Optimization Techniques**:

- [ ] **Partitioning** - Prune irrelevant data scans via partition filters (`WHERE year = 2024 AND month = 12`)
- [ ] **Z-Ordering** (Delta Lake) - Co-locate related data for multi-column filters (`OPTIMIZE table ZORDER BY (customer_id, order_date)`)
- [ ] **Bloom Filters** (Delta Lake) - Skip files without matching values (high-cardinality columns like IDs)
- [ ] **Data Skipping** - Delta Lake statistics automatically skip files
- [ ] **Caching** - Delta Cache (Databricks SSD-based) or Result Set Cache (Synapse)
- [ ] **Materialized Views** - Pre-compute expensive aggregations
- [ ] **Statistics Collection** - `ANALYZE TABLE` for cost-based optimizer

**Optimization Schedule**:

- Run `OPTIMIZE` on tables: [ ] Daily [ ] Weekly
- Run `VACUUM` to remove old files (retention: \_\_\_ days, default 7 days)
- Collect statistics: [ ] After major ingestion [ ] Weekly

**Example Optimization**:

```sql
-- Compact small files and z-order by frequently filtered columns
OPTIMIZE gold_sales_fact_sales ZORDER BY (customer_id, order_date);

-- Remove old file versions (older than 30 days)
VACUUM gold_sales_fact_sales RETAIN 720 HOURS;

-- Collect statistics for query optimizer
ANALYZE TABLE gold_sales_fact_sales COMPUTE STATISTICS FOR ALL COLUMNS;
```

### Section 9.2: Compute Optimization

#### For Azure Databricks

- [ ] **Photon Engine** - Vectorized execution engine for SQL/DataFrame operations (2-3x faster)
- [ ] **Adaptive Query Execution (AQE)** - Runtime query optimization (coalesce partitions, optimize joins)
- [ ] **Cluster Autoscaling** - Scale nodes based on workload (min: \_\_ nodes, max: \_\_ nodes)
- [ ] **Serverless SQL Warehouses** - Eliminate cluster management, instant startup (<5 sec)
- [ ] **Spot Instances** - Use Azure Spot VMs for non-critical workloads (up to 80% cost savings)

**Cluster Sizing**:

- Batch ETL jobs: [ ] Autoscaling clusters (cost-optimized)
- Interactive queries: [ ] Serverless SQL Warehouses (performance-optimized)
- Streaming: [ ] Fixed-size clusters (predictable performance)

#### For Microsoft Fabric

- [ ] **Serverless SQL Endpoint** - On-demand query execution (pay per query)
- [ ] **Fabric Warehouse** - Managed SQL warehouse (autoscaling compute)
- [ ] **Spark Autoscaling** - Dynamic node allocation for notebooks/pipelines

#### For Azure Synapse

- [ ] **Serverless SQL Pools** - On-demand querying (pay per TB scanned)
- [ ] **Dedicated SQL Pools** - Reserved capacity for predictable workloads (DWUs)
- [ ] **Spark Autoscaling** - Managed Spark pools with dynamic scaling

**Compute Selection Guidelines**:

- Development/exploration → Serverless (pay per use)
- Production batch ETL → Autoscaling clusters (cost vs. performance balance)
- Production real-time → Fixed clusters (predictable latency)

### Section 9.3: Storage Optimization

**File Size Management**:

- [ ] **Target file size**: \_\_\_ MB per file (128-512 MB recommended for Parquet/Delta)
- [ ] **Run OPTIMIZE** - Compact small files into larger files (reduces metadata overhead)
- [ ] **Avoid small files** - Small files (<10 MB) degrade performance significantly

**Compression Strategy**:

- [ ] **Cold/archival data** (rarely queried): Zstandard (zstd) - Max compression (~40% better than Snappy)
- [ ] **Hot data** (frequently queried): Snappy - Fast decompression, moderate compression

**Storage Tiering** (Azure Blob Storage):

- [ ] **Hot tier** - Frequently accessed data (Gold layer, recent Bronze/Silver)
- [ ] **Cool tier** - Infrequently accessed data (Bronze older than 90 days)
- [ ] **Archive tier** - Long-term retention, compliance (Bronze older than 1 year)

**Lifecycle Management**:

- Auto-transition Bronze data to Cool tier after: \_\_\_ days
- Auto-transition Bronze data to Archive tier after: \_\_\_ days
- Auto-delete archived data after: \_\_\_ years (if permitted by compliance)

### Section 9.4: Cost Monitoring & Optimization

**Cost Tracking**:

- [ ] **Databricks Cost Analysis** - Track DBU consumption by workspace/cluster/user
- [ ] **Azure Cost Management** - Monitor storage, compute, networking costs
- [ ] **Fabric Capacity Monitoring** - Track CU (Capacity Unit) usage
- [ ] **Chargeback/Showback** - Allocate costs to business units/projects

**Cost Optimization Actions**:

- [ ] **Right-size clusters** - Avoid over-provisioning (monitor CPU/memory utilization)
- [ ] **Use Spot VMs** - For non-production or fault-tolerant workloads
- [ ] **Schedule clusters** - Auto-terminate idle clusters after \_\_\_ minutes
- [ ] **Optimize data retention** - Delete or archive old data not needed for analytics
- [ ] **Partition pruning** - Ensure queries leverage partitions to minimize scanned data

**Cost Optimization Targets**:

- Reduce storage costs by: \_\_% (via compression, tiering, retention policies)
- Reduce compute costs by: \_\_% (via autoscaling, Spot VMs, query optimization)

---

## Article X: DataOps & CI/CD for Data Platforms

> **📋 Applies to**: Data Engineering projects with production deployments
> **⏭️ Skip if**: Prototypes, ad-hoc analytics only

**DataOps** is the practice of applying DevOps principles to data engineering, including version control, automated testing, continuous integration/deployment, and monitoring for data pipelines and analytics platforms.

### Section 10.1: Source Control Strategy

**Git Integration Platform** - Select ONE:

- [ ] **Microsoft Fabric Git Integration** - Native Fabric workspace sync with Azure DevOps/GitHub
- [ ] **Azure Databricks Repos** - Git integration for notebooks, libraries, DLT pipelines
- [ ] **Azure DevOps Repos** - Traditional Git with custom deployment scripts
- [ ] **GitHub** - With GitHub Actions for CI/CD automation
- [ ] **Hybrid** - Fabric Git + Databricks Repos (multi-platform projects)

**Version Control Scope**:

- [ ] **Pipelines/Notebooks** - ETL/ELT transformation code, orchestration workflows
- [ ] **Data definitions** - Table schemas, Delta Live Tables (DLT) declarations
- [ ] **SQL scripts** - Views, stored procedures, migrations
- [ ] **Configuration** - Connection strings (parameterized), environment variables
- [ ] **Infrastructure as Code** - Bicep/Terraform for data platform resources
- [ ] **Documentation** - Data dictionaries, lineage docs, runbooks

**Branching Strategy**:

- [ ] **GitFlow** - `main`, `develop`, `feature/`, `release/`, `hotfix/` (enterprise teams)
- [ ] **GitHub Flow** - `main` + `feature/*` branches (simpler, CI-friendly)
- [ ] **Trunk-Based Development** - Short-lived branches (<2 days), feature flags

**Branch-to-Workspace Mapping**:

| Git Branch      | Fabric/Databricks Workspace | Purpose              | Git Connected?               |
| --------------- | --------------------------- | -------------------- | ---------------------------- |
| `dev`           | DEV Workspace               | Active development   | ✅ Yes (bidirectional sync)  |
| `test` / `qa`   | TEST Workspace              | Integration testing  | ⚠️ Optional (deploy via API) |
| `prod` / `main` | PROD Workspace              | Production pipelines | ❌ No (deploy via API only)  |

**Recommended (Fabric)**: Only connect `dev` workspace to Git. Deploy to `test`/`prod` via deployment pipelines or REST APIs.

### Section 10.2: Continuous Integration (CI)

**CI Pipeline Triggers**:

- [ ] **Pull Request (PR) validation** - Run tests before merging
- [ ] **Commit to main** - Validate post-merge
- [ ] **Scheduled** - Nightly builds

**CI Checks for Data Pipelines**:

- [ ] **Linting** - SQL linting (SQLFluff), Python linting (Flake8, Black)
- [ ] **Unit tests** - Test transformation logic (pytest, PySpark tests)
- [ ] **Data quality tests** - Schema/constraints validation (Great Expectations, DLT Expectations)
- [ ] **Pipeline validation** - Syntax check without full run
- [ ] **Security scanning** - Detect hardcoded secrets (detect-secrets, Trivy)

**Testing Frameworks**:

| Test Type             | Tool                              | Purpose                   |
| --------------------- | --------------------------------- | ------------------------- |
| **Unit tests**        | pytest, Jest                      | Test individual functions |
| **Data quality**      | Great Expectations, DLT           | Validate data rules       |
| **Integration**       | Databricks Workflows, Fabric Test | End-to-end pipeline tests |
| **Schema validation** | Delta Lake, JSON Schema           | Schema compatibility      |

### Section 10.3: Continuous Deployment (CD)

**Deployment Strategy** - Select ONE:

- [ ] **Fabric Deployment Pipelines** - Native UI-driven (dev → test → prod)
- [ ] **Fabric REST APIs** - Programmatic via `fabric-cicd` Python package
- [ ] **Databricks Asset Bundles (DABs)** - YAML-based deployment
- [ ] **Azure DevOps Release Pipelines** - Manual approvals
- [ ] **GitHub Actions** - YAML workflows with protection rules
- [ ] **Terraform** - IaC-driven deployment

**Deployment Environments**:

| Environment | Trigger                 | Approval    | Rollback          |
| ----------- | ----------------------- | ----------- | ----------------- |
| **DEV**     | Auto on commit to `dev` | ❌ No       | Git revert        |
| **TEST**    | Auto on PR merge        | ⚠️ Optional | Redeploy previous |
| **PROD**    | Manual                  | ✅ Yes      | Delta Time Travel |

**Deployment Scope** - Select what gets deployed:

- [ ] **Pipelines** - ADF/Fabric pipelines, Databricks workflows
- [ ] **Notebooks** - Spark notebooks, SQL notebooks
- [ ] **Tables** - Delta tables (schema only, not data)
- [ ] **Views** - SQL views, materialized views
- [ ] **Libraries** - Python packages, JAR files
- [ ] **Compute** - Cluster configurations (via IaC)
- [ ] **Secrets** - Key Vault references (not actual secrets)

### Section 10.4: Environment Configuration

**Configuration Strategy**:

- [ ] **Fabric Variable Libraries** - Centralized variables per workspace
- [ ] **Azure Key Vault** - Secrets management
- [ ] **Databricks Secrets** - Scope-based (backed by Key Vault)
- [ ] **Environment Files** - `.env` for local dev (gitignored)
- [ ] **Deployment Rules (Fabric)** - Override lakehouse IDs per environment

**Environment-Specific Values**:

| Config                | DEV         | TEST         | PROD         |
| --------------------- | ----------- | ------------ | ------------ |
| **Lakehouse ID**      | dev-lh-123  | test-lh-456  | prod-lh-789  |
| **Azure SQL**         | dev-sql     | test-sql     | prod-sql     |
| **Service Principal** | sp-data-dev | sp-data-test | sp-data-prod |
| **Storage**           | devdatalake | testdatalake | proddatalake |

### Section 10.5: Data Pipeline Testing

**Test Pyramid for Data**:

```text
     /\       End-to-End (few, slow)
    /  \
   /____\     Integration (some, medium)
  /      \
 /________\   Unit Tests (many, fast)
```

**Unit Tests** - Test individual transformations:

```python
# tests/unit/test_transformations.py
def test_clean_customer_data_removes_nulls():
    input_df = spark.createDataFrame([
        (1, "Alice", "alice@ex.com"),
        (2, None, "bob@ex.com"),  # Null name
    ], ["id", "name", "email"])

    result = clean_customer_data(input_df)

    assert result.count() == 1
    assert result.collect()[0].name == "Alice"
```

**Integration Tests** - Full pipeline on sample data:

```python
# tests/integration/test_pipeline.py
def test_bronze_to_silver_pipeline():
    # Load sample to bronze
    spark.createDataFrame([...]).write.save("/bronze/orders")

    # Run pipeline
    run_bronze_to_silver_pipeline()

    # Verify silver output
    silver = spark.read.load("/silver/orders")
    assert silver.count() > 0
```

**Data Quality Tests**:

```python
# Great Expectations
ge_df.expect_column_values_to_not_be_null("order_id")
ge_df.expect_column_values_to_be_between("amount", 0, 1000000)
```

### Section 10.6: Monitoring & Observability

**Data Pipeline Monitoring**:

- [ ] **Fabric Monitoring Hub** - Pipeline runs, failures, duration
- [ ] **Databricks Jobs UI** - Job runs, cluster utilization
- [ ] **Azure Monitor** - Metrics, logs, alerts
- [ ] **Application Insights** - Custom telemetry
- [ ] **Databricks System Tables** - Historical audit (Unity Catalog)

**Key Metrics**:

| Metric                    | Tool               | Alert Threshold          |
| ------------------------- | ------------------ | ------------------------ |
| **Pipeline failure rate** | Fabric/Databricks  | > 5% in 24h              |
| **Pipeline duration**     | Fabric/Databricks  | > 2x baseline            |
| **Data freshness**        | Custom SQL         | Data older than \_\_ hrs |
| **Data quality score**    | Great Expectations | < 95% pass               |
| **Compute cost**          | Cost Management    | > budget %               |

**Alerting**:

- [ ] **Email** - Notify data engineers on failures
- [ ] **Teams/Slack** - Real-time alerts
- [ ] **PagerDuty** - On-call escalation
- [ ] **Auto-remediation** - Trigger retry/rollback

### Section 10.7: Rollback & Disaster Recovery

**Rollback Strategy**:

- [ ] **Delta Time Travel** - Restore table to previous version

  ```sql
  RESTORE TABLE silver_orders TO VERSION AS OF 123;
  ```

- [ ] **Git Revert** - Revert code and redeploy

  ```bash
  git revert <commit-hash>
  git push; # Trigger CD
  ```

- [ ] **Blue-Green Deployment** - Run old/new pipelines in parallel

**Disaster Recovery**:

- [ ] **Backup frequency**: [ ] Daily [ ] Weekly Bronze layer backups
- [ ] **RPO** (max data loss): \_\_\_ hours
- [ ] **RTO** (max downtime): \_\_\_ hours
- [ ] **Geo-redundancy**: [ ] Yes [ ] No - Replicate to secondary region

**DR Testing**: [ ] Quarterly [ ] Semi-annually [ ] Annually

---

## Article XIX: Governance 🔄

> **📋 Applies to**: ALL project types

### Section 19.1: Constitution Amendments

1. **Proposal**: Any team member may propose amendments via pull request
2. **Review**: Tech Lead + Data Architect + Data Governance Lead review required
3. **Approval**: Majority approval from signatories
4. **Implementation**: Update constitution + notify AI agents
5. **Versioning**: Semantic versioning (MAJOR.MINOR.PATCH)

### Section 19.2: AI Agent Compliance

All AI agents operating in this project MUST:

1. **Read** this constitution before any data-related operation
2. **Validate** all decisions against constitution principles
3. **FAIL** operations that violate constitution (e.g., creating non-Delta tables when Delta is mandated)
4. **Request** amendment for justified exceptions (document in ADR)
5. **Log** all constitution checks for audit trail

---

## Signatories

| Role                 | Name   | Date   | Signature |
| -------------------- | ------ | ------ | --------- |
| Project Lead         | [NAME] | [DATE] |           |
| Data Architect       | [NAME] | [DATE] |           |
| Data Engineer Lead   | [NAME] | [DATE] |           |
| Data Governance Lead | [NAME] | [DATE] |           |

---

## Revision History

| Version | Date       | Author   | Changes                                                                                          |
| ------- | ---------- | -------- | ------------------------------------------------------------------------------------------------ |
| 3.0.0   | 2026-02-27 | AI Agent | Complete rewrite - Focus on analytical architectures (Medallion, Lakehouse, ETL/ELT, Governance) |
| 2.1.0   | [DATE]     | [AUTHOR] | Added Project Scope (App/Infra/Full Stack), Landing Zone templates                               |
| 2.0.0   | [DATE]     | [AUTHOR] | Complete rewrite with C#/Node.js options                                                         |
| 1.0.0   | [DATE]     | [AUTHOR] | Initial constitution                                                                             |
