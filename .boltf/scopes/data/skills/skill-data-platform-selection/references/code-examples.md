# Data Platform Selection - Code Examples

## 1. Azure SQL Database - OLTP Relational (C#)

```csharp
using Microsoft.Data.SqlClient;
using Dapper;

// Connection with Azure AD authentication and retry policy
var connectionString = new SqlConnectionStringBuilder
{
    DataSource = "myserver.database.windows.net",
    InitialCatalog = "OrdersDB",
    Authentication = SqlAuthenticationMethod.ActiveDirectoryDefault, // Managed Identity
    Encrypt = true,
    ConnectRetryCount = 3,
    ConnectRetryInterval = 10
}.ConnectionString;

using var connection = new SqlConnection(connectionString);

// OLTP: Insert order with transaction
using var transaction = connection.BeginTransaction();
try
{
    var orderId = await connection.QuerySingleAsync<int>(
        "INSERT INTO Orders (CustomerId, OrderDate, TotalAmount) OUTPUT INSERTED.OrderId VALUES (@CustomerId, @OrderDate, @TotalAmount)",
        new { CustomerId = 12345, OrderDate = DateTime.UtcNow, TotalAmount = 599.99m },
        transaction);

    await connection.ExecuteAsync(
        "INSERT INTO OrderItems (OrderId, ProductId, Quantity, Price) VALUES (@OrderId, @ProductId, @Quantity, @Price)",
        new[]
        {
            new { OrderId = orderId, ProductId = 101, Quantity = 2, Price = 299.99m },
            new { OrderId = orderId, ProductId = 205, Quantity = 1, Price = 299.99m }
        },
        transaction);

    transaction.Commit();
    Console.WriteLine($"Order {orderId} created with 2 items");
}
catch
{
    transaction.Rollback();
    throw;
}

// Read with high concurrency (default READ COMMITTED isolation)
var recentOrders = await connection.QueryAsync<Order>(
    "SELECT TOP 100 OrderId, CustomerId, OrderDate, TotalAmount FROM Orders WHERE OrderDate >= @Since ORDER BY OrderDate DESC",
    new { Since = DateTime.UtcNow.AddDays(-7) });
```

## 2. Azure Cosmos DB - NoSQL Global Distribution (Python)

```python
from azure.cosmos import CosmosClient, PartitionKey, exceptions
import uuid

# Connect with multi-region write
client = CosmosClient(url=cosmos_endpoint, credential=cosmos_key)
database = client.create_database_if_not_exists("EcommerceDB")

# Create container with partition key for horizontal scaling
container = database.create_container_if_not_exists(
    id="Products",
    partition_key=PartitionKey(path="/category"),  # Distribute by category
    offer_throughput=400  # 400 RU/s (scale to 1M+ RU/s)
)

# Insert document (schema-free JSON)
product = {
    "id": str(uuid.uuid4()),
    "category": "Electronics",  # Partition key value
    "name": "Wireless Mouse",
    "description": "Ergonomic design with USB-C",
    "price": 29.99,
    "stock": 150,
    "tags": ["wireless", "ergonomic", "usb-c"],
    "metadata": {
        "manufacturer": "TechCorp",
        "warranty_years": 2
    }
}

container.create_item(body=product)

# Query within partition (efficient, low RU cost)
query = "SELECT * FROM c WHERE c.category = @category AND c.price < @maxPrice"
items = list(container.query_items(
    query=query,
    parameters=[
        {"name": "@category", "value": "Electronics"},
        {"name": "@maxPrice", "value": 50.0}
    ],
    partition_key="Electronics"  # Single-partition query = low cost
))

# Cross-partition query (higher RU cost)
all_cheap = list(container.query_items(
    query="SELECT * FROM c WHERE c.price < 30",
    enable_cross_partition_query=True  # Queries all partitions
))

# Strongly consistent read from specific region
item = container.read_item(
    item=product['id'],
    partition_key=product['category'],
    consistency_level="Strong"  # Options: Strong, Bounded Staleness, Session, Consistent Prefix, Eventual
)
```

## 3. Azure Synapse Analytics - Data Warehouse OLAP (SQL)

```sql
-- Dedicated SQL Pool (formerly SQL Data Warehouse) for OLAP queries
-- Massively parallel processing (MPP) architecture with distributions

-- Create fact table with hash distribution on high-cardinality key
CREATE TABLE dbo.FactSales
(
    SaleId BIGINT NOT NULL,
    DateKey INT NOT NULL,
    CustomerId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    Region VARCHAR(50) NOT NULL
)
WITH
(
    DISTRIBUTION = HASH(CustomerId),  -- Distribute across 60 compute nodes
    CLUSTERED COLUMNSTORE INDEX       -- Columnar storage for analytics
);

-- Create dimension table with replicated distribution (broadcast to all nodes)
CREATE TABLE dbo.DimProduct
(
    ProductId INT NOT NULL,
    ProductName VARCHAR(200) NOT NULL,
    Category VARCHAR(100) NOT NULL,
    Subcategory VARCHAR(100) NOT NULL,
    Price DECIMAL(18,2) NOT NULL
)
WITH
(
    DISTRIBUTION = REPLICATE,  -- Copy to all 60 distributions for fast joins
    CLUSTERED COLUMNSTORE INDEX
);

-- OLAP query: Aggregation across billions of rows
SELECT
    p.Category,
    p.Subcategory,
    YEAR(d.CalendarDate) AS Year,
    MONTH(d.CalendarDate) AS Month,
    COUNT(DISTINCT f.CustomerId) AS UniqueCustomers,
    SUM(f.Quantity) AS TotalQuantity,
    SUM(f.Amount) AS TotalRevenue,
    AVG(f.Amount) AS AvgOrderValue
FROM dbo.FactSales f
INNER JOIN dbo.DimProduct p ON f.ProductId = p.ProductId
INNER JOIN dbo.DimDate d ON f.DateKey = d.DateKey
WHERE d.CalendarYear >= 2022
GROUP BY p.Category, p.Subcategory, YEAR(d.CalendarDate), MONTH(d.CalendarDate)
ORDER BY TotalRevenue DESC;

-- Partition table by date for lifecycle management
CREATE TABLE dbo.FactSalesPartitioned
(
    SaleId BIGINT NOT NULL,
    SaleDate DATE NOT NULL,
    Amount DECIMAL(18,2) NOT NULL
)
WITH
(
    DISTRIBUTION = HASH(SaleId),
    PARTITION (SaleDate RANGE RIGHT FOR VALUES
        ('2023-01-01', '2023-02-01', '2023-03-01', '2023-04-01'))  -- Monthly partitions
);

-- Switch old partition to archive table (instant operation, no data movement)
ALTER TABLE dbo.FactSalesPartitioned SWITCH PARTITION 1 TO dbo.FactSalesArchive;
```

## 4. Azure Data Lake Storage Gen2 - Data Lake (Python with PySpark)

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, year, month, sum, avg, count

# Connect Spark to Azure Data Lake Storage Gen2 (ADLS Gen2)
spark = SparkSession.builder \
    .appName("DataLakeAnalytics") \
    .config("fs.azure.account.auth.type", "OAuth") \
    .config("fs.azure.account.oauth.provider.type", "org.apache.hadoop.fs.azurebfs.oauth2.MsiTokenProvider") \
    .getOrCreate()

# Read raw CSV from bronze layer (raw ingestion)
raw_path = "abfss://bronze@mydatalake.dfs.core.windows.net/sales/2024/*.csv"
df_raw = spark.read.csv(raw_path, header=True, inferSchema=True)

# Transform and write to silver layer (curated parquet with partitioning)
df_silver = df_raw \
    .withColumn("year", year(col("sale_date"))) \
    .withColumn("month", month(col("sale_date"))) \
    .filter(col("amount") > 0) \
    .dropDuplicates(["transaction_id"])

silver_path = "abfss://silver@mydatalake.dfs.core.windows.net/sales"
df_silver.write \
    .mode("overwrite") \
    .partitionBy("year", "month") \
    .parquet(silver_path)

# Aggregate to gold layer (business-ready analytics)
df_gold = df_silver \
    .groupBy("year", "month", "product_category") \
    .agg(
        count("transaction_id").alias("transaction_count"),
        sum("amount").alias("total_revenue"),
        avg("amount").alias("avg_transaction_value")
    )

gold_path = "abfss://gold@mydatalake.dfs.core.windows.net/sales_summary"
df_gold.write \
    .mode("overwrite") \
    .format("delta") \
    .save(gold_path)

# Query Delta Lake table with time travel
df_gold_version = spark.read \
    .format("delta") \
    .option("versionAsOf", 5) \
    .load(gold_path)
```

## 5. Azure Database for PostgreSQL - Open-Source Relational (Python)

```python
import psycopg2
from psycopg2.extras import execute_values

# Connect with SSL and connection pooling
conn = psycopg2.connect(
    host="mypostgres.postgres.database.azure.com",
    database="inventory",
    user="adminuser@mypostgres",
    password="...",
    sslmode="require",
    connect_timeout=10
)

cur = conn.cursor()

# Create table with JSONB column (flexible schema within relational model)
cur.execute("""
    CREATE TABLE IF NOT EXISTS products (
        product_id SERIAL PRIMARY KEY,
        name VARCHAR(200) NOT NULL,
        category VARCHAR(100) NOT NULL,
        price NUMERIC(10,2) NOT NULL,
        attributes JSONB,  -- Store flexible attributes as JSON
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
""")

# Create GIN index on JSONB for fast queries
cur.execute("CREATE INDEX IF NOT EXISTS idx_attributes ON products USING GIN (attributes)")

# Insert with JSONB attributes
products = [
    ("Laptop", "Electronics", 1299.99, {"brand": "Dell", "ram_gb": 16, "storage_gb": 512, "ports": ["USB-C", "HDMI"]}),
    ("Mouse", "Accessories", 29.99, {"brand": "Logitech", "wireless": True, "battery_type": "AA"})
]

execute_values(
    cur,
    "INSERT INTO products (name, category, price, attributes) VALUES %s",
    products,
    template="(%s, %s, %s, %s::jsonb)"
)
conn.commit()

# Query JSONB with @> containment operator
cur.execute("""
    SELECT product_id, name, price, attributes
    FROM products
    WHERE attributes @> '{"wireless": true}'::jsonb
""")

for row in cur.fetchall():
    print(f"Product: {row[1]}, Price: ${row[2]}, Attributes: {row[3]}")

# PostgreSQL-specific: Full-text search
cur.execute("""
    SELECT name, price
    FROM products
    WHERE to_tsvector('english', name || ' ' || category) @@ to_tsquery('english', 'laptop & electronics')
""")
```

## 6. Azure Data Factory - ETL/ELT Orchestration (JSON Pipeline)

```json
{
  "name": "IncrementalLoadPipeline",
  "properties": {
    "activities": [
      {
        "name": "LookupLastWatermark",
        "type": "Lookup",
        "typeProperties": {
          "source": {
            "type": "AzureSqlSource",
            "sqlReaderQuery": "SELECT MAX(last_modified) AS watermark FROM watermark_table WHERE table_name = 'Orders'"
          },
          "dataset": {
            "referenceName": "AzureSqlDatabase"
          }
        }
      },
      {
        "name": "CopyIncrementalData",
        "type": "Copy",
        "dependsOn": [
          {
            "activity": "LookupLastWatermark",
            "dependencyConditions": ["Succeeded"]
          }
        ],
        "typeProperties": {
          "source": {
            "type": "AzureSqlSource",
            "sqlReaderQuery": {
              "value": "@concat('SELECT * FROM Orders WHERE last_modified > ''', activity('LookupLastWatermark').output.firstRow.watermark, '''')",
              "type": "Expression"
            }
          },
          "sink": {
            "type": "ParquetSink",
            "storeSettings": {
              "type": "AzureBlobFSWriteSettings",
              "copyBehavior": "PreserveHierarchy"
            }
          },
          "enableStaging": false,
          "parallelCopies": 4,
          "dataIntegrationUnits": 8
        },
        "inputs": [
          {
            "referenceName": "SourceAzureSqlTable",
            "type": "DatasetReference"
          }
        ],
        "outputs": [
          {
            "referenceName": "SinkDataLakeParquet",
            "type": "DatasetReference"
          }
        ]
      },
      {
        "name": "UpdateWatermark",
        "type": "SqlServerStoredProcedure",
        "dependsOn": [
          {
            "activity": "CopyIncrementalData",
            "dependencyConditions": ["Succeeded"]
          }
        ],
        "typeProperties": {
          "storedProcedureName": "usp_UpdateWatermark",
          "storedProcedureParameters": {
            "tableName": {
              "value": "Orders",
              "type": "String"
            },
            "watermarkValue": {
              "value": {
                "value": "@utcnow()",
                "type": "Expression"
              },
              "type": "DateTime"
            }
          }
        }
      }
    ],
    "parameters": {},
    "annotations": []
  }
}
```

## 7. Azure Databricks - Unified Analytics (Python)

```python
# Databricks notebook: Unified batch and streaming analytics

from pyspark.sql import SparkSession
from pyspark.sql.functions import window, col, sum, avg, count
from delta.tables import DeltaTable

spark = SparkSession.builder.appName("UnifiedAnalytics").getOrCreate()

# Batch processing: Read from Delta Lake
df_batch = spark.read.format("delta").load("/mnt/datalake/sales")

# Streaming processing: Read from Event Hub
df_stream = spark.readStream \
    .format("eventhubs") \
    .option("eventhubs.connectionString", connection_string) \
    .option("eventhubs.consumerGroup", "$Default") \
    .load()

# Transform streaming data (real-time aggregation)
df_aggregated = df_stream \
    .selectExpr("CAST(body AS STRING) as json") \
    .select(from_json(col("json"), schema).alias("data")) \
    .select("data.*") \
    .withWatermark("timestamp", "10 minutes") \
    .groupBy(
        window(col("timestamp"), "5 minutes", "1 minute"),  # 5-min window, 1-min slide
        col("product_category")
    ) \
    .agg(
        count("*").alias("event_count"),
        sum("amount").alias("total_amount")
    )

# Write stream to Delta Lake (ACID transactions for streaming)
query = df_aggregated.writeStream \
    .format("delta") \
    .outputMode("append") \
    .option("checkpointLocation", "/mnt/checkpoints/sales_agg") \
    .trigger(processingTime="1 minute") \
    .start("/mnt/datalake/sales_realtime")

# Merge streaming updates into dimension table (UPSERT)
def upsert_to_delta(batch_df, batch_id):
    delta_table = DeltaTable.forPath(spark, "/mnt/datalake/product_inventory")

    delta_table.alias("target").merge(
        batch_df.alias("source"),
        "target.product_id = source.product_id"
    ).whenMatchedUpdate(set={
        "stock_quantity": "target.stock_quantity + source.quantity_change",
        "last_updated": "source.timestamp"
    }).whenNotMatchedInsert(values={
        "product_id": "source.product_id",
        "stock_quantity": "source.quantity_change",
        "last_updated": "source.timestamp"
    }).execute()

df_stream.writeStream \
    .foreachBatch(upsert_to_delta) \
    .outputMode("update") \
    .start()
```

## 8. Platform Selection Decision Matrix

```python
# Decision matrix: Input your requirements, output recommended platform

requirements = {
    "workload_type": "OLTP",  # OLTP, OLAP, Hybrid, Analytics, Streaming
    "data_model": "Relational",  # Relational, NoSQL, Graph, TimeSeries, Analytical
    "scale": "100GB",  # 1GB, 100GB, 10TB, 1PB+
    "latency": "ms",  # ms (milliseconds), seconds, minutes, hours
    "consistency": "Strong",  # Strong, Eventual, Session
    "global_distribution": False,  # True/False
    "query_complexity": "Simple",  # Simple (key-value), Medium (SQL), Complex (joins+agg)
    "schema_flexibility": "Fixed"  # Fixed (schema), Flexible (schema-on-read), Hybrid
}

def recommend_platform(req):
    # OLTP relational with strong consistency
    if req["workload_type"] == "OLTP" and req["data_model"] == "Relational":
        if req["global_distribution"]:
            return "Azure SQL Database (Hyperscale with geo-replication)"
        return "Azure SQL Database (General Purpose or Business Critical)"

    # NoSQL with global distribution
    elif req["data_model"] == "NoSQL" and req["global_distribution"]:
        return "Azure Cosmos DB (multi-region write)"

    # OLAP data warehouse
    elif req["workload_type"] == "OLAP" and req["scale"] in ["10TB", "1PB+"]:
        return "Azure Synapse Analytics (Dedicated SQL Pool)"

    # Analytics with schema-on-read
    elif req["workload_type"] == "Analytics" and req["schema_flexibility"] == "Flexible":
        return "Azure Data Lake Storage Gen2 + Databricks"

    # Real-time streaming analytics
    elif req["workload_type"] == "Streaming":
        return "Azure Databricks (Structured Streaming) or Azure Stream Analytics"

    # Open-source with hybrid schema
    elif req["data_model"] == "Relational" and req["schema_flexibility"] == "Hybrid":
        return "Azure Database for PostgreSQL (with JSONB)"

    else:
        return "Review Azure data services decision tree"

recommended = recommend_platform(requirements)
print(f"Recommended platform: {recommended}")
```

---

**Key Patterns by Use Case:**

- **OLTP with transactions**: Azure SQL Database, PostgreSQL
- **NoSQL global scale**: Azure Cosmos DB
- **OLAP data warehouse**: Azure Synapse Analytics (Dedicated SQL Pool)
- **Big data analytics**: Azure Data Lake Gen2 + Databricks
- **Real-time streaming**: Azure Databricks, Stream Analytics, Event Hubs
- **ETL orchestration**: Azure Data Factory, Synapse Pipelines
