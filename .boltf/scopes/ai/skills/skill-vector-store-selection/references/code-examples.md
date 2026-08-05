# Vector Store Selection - Code Examples

## 1. Azure AI Search - Vector Index and Search (C#)

```csharp
using Azure;
using Azure.Search.Documents;
using Azure.Search.Documents.Indexes;
using Azure.Search.Documents.Indexes.Models;
using Azure.Search.Documents.Models;

// Create vector index
var indexClient = new SearchIndexClient(new Uri(searchEndpoint), new AzureKeyCredential(searchApiKey));

var fieldBuilder = new FieldBuilder();
var searchFields = fieldBuilder.Build(typeof(ProductDocument));

var definition = new SearchIndex("products-vector-index", searchFields)
{
    VectorSearch = new VectorSearch
    {
        Algorithms = { new HnswAlgorithmConfiguration("hnsw-config") { Parameters = new HnswParameters { M = 4, EfConstruction = 400 } } },
        Profiles = { new VectorSearchProfile("vector-profile", "hnsw-config") }
    }
};

await indexClient.CreateOrUpdateIndexAsync(definition);

// Index documents with embeddings
var searchClient = indexClient.GetSearchClient("products-vector-index");
var documents = new[]
{
    new ProductDocument
    {
        Id = "1",
        Name = "Wireless Mouse",
        Description = "Ergonomic wireless mouse with USB receiver",
        DescriptionVector = await GetEmbeddingsAsync("Ergonomic wireless mouse") // 1536-dim float array
    }
};
await searchClient.IndexDocumentsAsync(IndexDocumentsBatch.Upload(documents));

// Vector search with text query
var queryEmbedding = await GetEmbeddingsAsync("comfortable mouse for office work");
var searchOptions = new SearchOptions
{
    Vectors = { new SearchQueryVector { KNearestNeighborsCount = 5, Fields = { "descriptionVector" }, Value = queryEmbedding } },
    Size = 5
};
var results = await searchClient.SearchAsync<ProductDocument>(null, searchOptions);
```

## 2. Azure Cosmos DB for MongoDB vCore - Vector Search

```python
from pymongo import MongoClient
from azure.ai.openai import OpenAIClient

# Connect to Cosmos DB for MongoDB vCore
client = MongoClient(connection_string)
db = client["product_catalog"]
collection = db["products"]

# Create vector index
collection.create_index([("descriptionVector", "cosmosSearch")],
                       cosmosSearchOptions={
                           "kind": "vector-hnsw",
                           "dimensions": 1536,
                           "similarity": "cosine",
                           "m": 16,
                           "efConstruction": 64
                       })

# Insert document with embedding
openai_client = OpenAIClient(azure_endpoint, AzureKeyCredential(api_key))
description = "Premium wireless keyboard with backlight"
embedding = openai_client.embeddings.create(input=description, model="text-embedding-ada-002").data[0].embedding

collection.insert_one({
    "name": "Wireless Keyboard",
    "description": description,
    "descriptionVector": embedding,
    "category": "Electronics"
})

# Vector search
query = "backlit keyboard for typing"
query_embedding = openai_client.embeddings.create(input=query, model="text-embedding-ada-002").data[0].embedding

pipeline = [
    {
        "$search": {
            "cosmosSearch": {
                "vector": query_embedding,
                "path": "descriptionVector",
                "k": 5
            },
            "returnStoredSource": True
        }
    },
    {"$project": {"descriptionVector": 0}}  # Exclude vector from results
]

results = collection.aggregate(pipeline)
for doc in results:
    print(f"{doc['name']}: {doc['description']}")
```

## 3. PostgreSQL with pgvector - Vector Search

```sql
-- Install pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create table with vector column
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    description TEXT,
    description_vector vector(1536),  -- 1536 dimensions for text-embedding-ada-002
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create HNSW index for fast approximate nearest neighbor search
CREATE INDEX ON products USING hnsw (description_vector vector_cosine_ops) WITH (m = 16, ef_construction = 64);

-- Insert document with embedding (from application code)
-- Example in Python:
```

```python
import psycopg2
from pgvector.psycopg2 import register_vector
from openai import AzureOpenAI

conn = psycopg2.connect(database="products_db", user="admin", password="...", host="...")
register_vector(conn)

openai_client = AzureOpenAI(azure_endpoint=endpoint, api_key=api_key, api_version="2024-02-01")

def get_embedding(text):
    return openai_client.embeddings.create(input=text, model="text-embedding-ada-002").data[0].embedding

cur = conn.cursor()

# Insert with embedding
description = "Noise-canceling wireless headphones"
embedding = get_embedding(description)
cur.execute("INSERT INTO products (name, description, description_vector) VALUES (%s, %s, %s)",
           ("Wireless Headphones", description, embedding))

# Vector similarity search with cosine distance
query = "headphones for focus"
query_embedding = get_embedding(query)
cur.execute("""
    SELECT name, description, 1 - (description_vector <=> %s) AS similarity
    FROM products
    ORDER BY description_vector <=> %s
    LIMIT 5
""", (query_embedding, query_embedding))

for name, desc, similarity in cur.fetchall():
    print(f"{name} (similarity: {similarity:.4f}): {desc}")
```

## 4. Redis with Vector Search (RedisVL)

```python
from redisvl.index import SearchIndex
from redisvl.query import VectorQuery
from openai import AzureOpenAI

# Define vector index schema
schema = {
    "index": {
        "name": "products_idx",
        "prefix": "product:",
        "storage_type": "hash"
    },
    "fields": [
        {"name": "name", "type": "text"},
        {"name": "description", "type": "text"},
        {
            "name": "description_vector",
            "type": "vector",
            "attrs": {
                "dims": 1536,
                "distance_metric": "cosine",
                "algorithm": "hnsw",
                "datatype": "float32"
            }
        }
    ]
}

# Create index
index = SearchIndex.from_dict(schema)
index.connect("redis://localhost:6379")
index.create(overwrite=True)

# Index document
openai_client = AzureOpenAI(azure_endpoint=endpoint, api_key=api_key, api_version="2024-02-01")
description = "Smart fitness tracker with heart rate monitor"
embedding = openai_client.embeddings.create(input=description, model="text-embedding-ada-002").data[0].embedding

index.load([{
    "name": "Fitness Tracker",
    "description": description,
    "description_vector": embedding
}], keys=["product:1"])

# Vector search
query = "heart rate monitoring device"
query_embedding = openai_client.embeddings.create(input=query, model="text-embedding-ada-002").data[0].embedding

vector_query = VectorQuery(
    vector=query_embedding,
    vector_field_name="description_vector",
    return_fields=["name", "description"],
    num_results=5
)

results = index.query(vector_query)
for doc in results:
    print(f"{doc['name']}: {doc['description']}")
```

## 5. In-Memory FAISS (Fast Approximate Nearest Neighbors)

```python
import faiss
import numpy as np
from openai import AzureOpenAI

# Initialize OpenAI client for embeddings
openai_client = AzureOpenAI(azure_endpoint=endpoint, api_key=api_key, api_version="2024-02-01")

def get_embedding(text):
    return openai_client.embeddings.create(input=text, model="text-embedding-ada-002").data[0].embedding

# Create FAISS index (HNSW for large datasets, Flat for small/exact search)
dimension = 1536
index = faiss.IndexHNSWFlat(dimension, 32)  # 32 = number of neighbors

# Store metadata separately (FAISS only stores vectors)
documents = [
    {"id": 0, "name": "Laptop", "description": "High-performance laptop for gaming"},
    {"id": 1, "name": "Monitor", "description": "4K HDR monitor with USB-C"},
    {"id": 2, "name": "Keyboard", "description": "Mechanical keyboard with RGB lighting"}
]

# Generate embeddings and add to index
embeddings = [get_embedding(doc["description"]) for doc in documents]
embeddings_array = np.array(embeddings, dtype=np.float32)
index.add(embeddings_array)

# Vector search
query = "computer display with high resolution"
query_embedding = np.array([get_embedding(query)], dtype=np.float32)

k = 2  # Number of nearest neighbors
distances, indices = index.search(query_embedding, k)

# Map results back to metadata
for i, (distance, idx) in enumerate(zip(distances[0], indices[0])):
    doc = documents[idx]
    similarity = 1 - distance  # Convert distance to similarity
    print(f"{i+1}. {doc['name']} (similarity: {similarity:.4f}): {doc['description']}")

# Save/load index for persistence
faiss.write_index(index, "products.index")
loaded_index = faiss.read_index("products.index")
```

## 6. Hybrid Search - Combining Vector and Keyword (Azure AI Search)

```csharp
using Azure.Search.Documents;
using Azure.Search.Documents.Models;

var searchClient = new SearchClient(new Uri(searchEndpoint), "products-index", new AzureKeyCredential(apiKey));

// Hybrid search: vector similarity + keyword BM25
var queryEmbedding = await GetEmbeddingsAsync("ergonomic office chair");

var searchOptions = new SearchOptions
{
    // Vector search component
    Vectors = { new SearchQueryVector
    {
        KNearestNeighborsCount = 50,  // Retrieve 50 candidates
        Fields = { "descriptionVector" },
        Value = queryEmbedding
    }},

    // Keyword search component (BM25) - search text across text fields
    SearchText = "ergonomic chair",
    SearchFields = { "name", "description", "category" },

    // Combine scores: RRF (Reciprocal Rank Fusion) - default in Azure AI Search
    Size = 10,

    // Filtering (applied before search)
    Filter = "category eq 'Furniture' and price lt 500",

    // Semantic ranking (optional third layer: re-rank with L2 model)
    QueryType = SearchQueryType.Semantic,
    SemanticConfigurationName = "products-semantic-config"
};

SearchResults<ProductDocument> results = await searchClient.SearchAsync<ProductDocument>(null, searchOptions);

await foreach (SearchResult<ProductDocument> result in results.GetResultsAsync())
{
    Console.WriteLine($"Score: {result.Score:F4} - {result.Document.Name}");
    Console.WriteLine($"  Vector Score: {result.SemanticSearch?.RerankerScore}");
    Console.WriteLine($"  Description: {result.Document.Description}");
}
```

## 7. Vector Store Comparison Table

| Feature                   | Azure AI Search               | Cosmos DB (MongoDB vCore)                | PostgreSQL (pgvector)               | Redis (Vector)             | FAISS (In-Memory)                     |
| ------------------------- | ----------------------------- | ---------------------------------------- | ----------------------------------- | -------------------------- | ------------------------------------- |
| **Managed Service**       | ✅ Fully managed              | ✅ Fully managed                         | ✅ Managed (Azure)                  | ⚠️ Self-hosted or managed  | ❌ In-process library                 |
| **Vector Algorithm**      | HNSW                          | HNSW, IVF                                | HNSW, IVF                           | HNSW                       | HNSW, IVF, Flat                       |
| **Hybrid Search**         | ✅ Built-in (vector + BM25)   | ⚠️ Requires manual                       | ⚠️ Manual (full-text + vector)      | ⚠️ Manual                  | ❌ Not supported                      |
| **Filtering**             | ✅ Pre-filter (fast)          | ✅ Pre-filter                            | ✅ Pre-filter (SQL WHERE)           | ✅ Pre-filter              | ⚠️ Post-filter only                   |
| **Semantic Ranking**      | ✅ Built-in L2 model          | ❌ Not available                         | ❌ Not available                    | ❌ Not available           | ❌ Not available                      |
| **Max Vector Dimensions** | 3072                          | 2000                                     | 16,000                              | 32,768                     | No limit                              |
| **Persistence**           | ✅ Durable                    | ✅ Durable                               | ✅ Durable                          | ✅ Durable (AOF/RDB)       | ❌ In-memory (save to disk)           |
| **Best For**              | Enterprise RAG, hybrid search | Global apps, document store with vectors | Existing PostgreSQL, cost-effective | Low-latency cache + search | Prototyping, research, small datasets |
| **Cost**                  | $$$ (per tier)                | $$ (per vCore hour)                      | $ (standard PostgreSQL pricing)     | $ (per GB)                 | Free (compute only)                   |
| **Scale**                 | Millions of docs              | Millions of docs                         | Millions of rows                    | Millions of keys           | Limited by RAM                        |

## 8. Vector Migration - Moving Between Stores

```python
from azure.search.documents import SearchClient
from pymongo import MongoClient
import psycopg2
from pgvector.psycopg2 import register_vector

# Source: Azure AI Search
source_client = SearchClient(endpoint=search_endpoint, index_name="source_index", credential=search_credential)
source_results = source_client.search("*", select=["id", "name", "description", "descriptionVector"], top=10000)

# Target: PostgreSQL with pgvector
conn = psycopg2.connect(database="target_db", user="admin", password="...", host="...")
register_vector(conn)
cur = conn.cursor()

# Batch migration
batch_size = 100
batch = []

for doc in source_results:
    batch.append((doc["id"], doc["name"], doc["description"], doc["descriptionVector"]))

    if len(batch) >= batch_size:
        cur.executemany(
            "INSERT INTO products (id, name, description, description_vector) VALUES (%s, %s, %s, %s) ON CONFLICT (id) DO NOTHING",
            batch
        )
        conn.commit()
        batch = []
        print(f"Migrated {cur.rowcount} documents")

# Insert remaining
if batch:
    cur.executemany(
        "INSERT INTO products (id, name, description, description_vector) VALUES (%s, %s, %s, %s) ON CONFLICT (id) DO NOTHING",
        batch
    )
    conn.commit()

print("Migration complete")

# Verify counts
cur.execute("SELECT COUNT(*) FROM products")
target_count = cur.fetchone()[0]
print(f"Target count: {target_count}")
```

---

**Recommended Patterns:**

- **Enterprise RAG**: Azure AI Search (hybrid search, semantic ranking, managed)
- **Global apps**: Cosmos DB for MongoDB vCore (multi-region, low latency)
- **Cost-effective**: PostgreSQL with pgvector (existing database, lower cost)
- **Low-latency cache**: Redis with vector search (sub-millisecond, ephemeral data)
- **Prototyping**: FAISS in-memory (no infrastructure, fast iteration)
- **Multi-cloud**: Pinecone, Weaviate, Qdrant (cloud-agnostic, managed)
