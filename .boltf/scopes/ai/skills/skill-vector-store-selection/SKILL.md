---
name: skill-vector-store-selection
description: Select vector database (Azure AI Search, Cosmos DB, PostgreSQL pgvector, Redis, FAISS, Pinecone) for RAG, semantic search, or embeddings storage. Use when implementing vector search, choosing embedding storage, designing hybrid search (vector + keyword), or migrating from FAISS prototype to production. Critical for RAG architectures - storage choice affects cost, latency, and scale.
---

# Vector Store Selection

## When to Use This Skill

Use this skill when making decisions about **vector store selection** for AI applications, because the wrong choice impacts cost, performance, and maintainability:

- **Implementing RAG (Retrieval-Augmented Generation) with embeddings storage** → Vector stores are the foundation for RAG, impacting query latency and relevance
- **Choosing between managed (Azure AI Search) vs self-hosted (pgvector) vector databases** → Managed services reduce operational burden but cost more; self-hosted requires expertise
- **Architecting hybrid search (vector + keyword filtering)** → Not all vector stores support efficient pre-filtering or keyword search integration
- **Scaling semantic search to millions of documents** → Indexing algorithms (HNSW, IVF) and sharding strategies differ across stores
- **Migrating from in-memory prototypes (FAISS) to production** → FAISS is fast for research but lacks persistence, multi-user access, and filtering
- **Optimizing cost for vector storage and queries** → Storage costs ($/GB embeddings) and query costs ($/1K queries) vary 10x across options
- **Integrating vectors into existing database infrastructure** → pgvector extends PostgreSQL, avoiding separate vector database; Cosmos DB adds vectors to NoSQL documents

## Decision Framework

```text
What's your vector store need?

├─ Enterprise RAG with hybrid search?
│  └─ Azure AI Search (managed, HNSW, vector+keyword+semantic ranking)
│
├─ Existing PostgreSQL database?
│  └─ pgvector extension (add vectors to current DB, cost-effective)
│
├─ Global low-latency document store?
│  └─ Cosmos DB for MongoDB vCore (multi-region, NoSQL+vectors)
│
├─ Low-latency cache + vector search?
│  └─ Redis with vector search (sub-ms latency, ephemeral data)
│
├─ Prototyping or research?
│  └─ FAISS in-memory (no infrastructure, fast iteration)
│
└─ Multi-cloud or specialized needs?
   └─ Pinecone/Weaviate/Qdrant (cloud-agnostic, advanced features)
```

## Scoring Model

Use this as a **conversation starter** to evaluate vector stores against your specific workload:

| Factor                    | Azure AI Search               | Cosmos DB (vCore)          | pgvector                    | Redis                  | FAISS                 | Pinecone/Weaviate        |
| ------------------------- | ----------------------------- | -------------------------- | --------------------------- | ---------------------- | --------------------- | ------------------------ |
| **Hybrid Search**         | Native (vector+BM25+semantic) | Manual                     | Manual (FTS+vector)         | Manual                 | Not supported         | Native (varies)          |
| **Managed Service**       | Fully managed                 | Fully managed              | Managed (Azure)             | Self-hosted or managed | In-process library    | Fully managed            |
| **Filtering Performance** | Pre-filter (fast)             | Pre-filter                 | Pre-filter (SQL WHERE)      | Pre-filter             | Post-filter (slow)    | Pre-filter               |
| **Max Vector Dims**       | 3,072                         | 2,000                      | 16,000                      | 32,768                 | Unlimited             | 20,000+                  |
| **Cost**                  | $$$ (per tier, S1 ~$250/mo)   | $$ (per vCore hour)        | $ (PostgreSQL pricing)      | $ (per GB)             | Free (compute only)   | $$ (per index/query)     |
| **Best For**              | Enterprise RAG                | Global apps, NoSQL+vectors | Cost-effective, existing DB | Low-latency cache      | Prototyping, research | Multi-cloud, specialized |

## Vector Store Patterns

### 1. Azure AI Search (Managed Hybrid Search)

**What**: Fully managed search service with native vector search, keyword search (BM25), and semantic ranking (L2 model).

**How it works**:

1. Create vector index with HNSW algorithm configuration (M=4-16, efConstruction=400-800 for quality)
2. Index documents with text fields + vector fields (embeddings from text-embedding-ada-002)
3. Query with vector similarity + keyword filters + optional semantic re-ranking (3-layer search)
4. Scale with replicas (query throughput) and partitions (index size)

**When to use**: Enterprise RAG with complex queries requiring hybrid search (vector + keyword + filtering). Example: Customer support chatbot searching 100K+ documents with metadata filters (date, category, region).

**Considerations**: Cost increases with scale (S1 tier ~$250/mo for 25GB, 3 replicas). HNSW parameters trade-off speed vs accuracy. Semantic ranking adds latency (L2 model inference) but improves relevance.

### 2. Cosmos DB for MongoDB vCore (Global NoSQL + Vectors)

**What**: MongoDB-compatible API with vector search built-in, globally distributed NoSQL database.

**How it works**:

1. Create cosmosSearch index on vector field (HNSW or IVF algorithm)
2. Insert documents with embeddings as vector arrays (dimensions up to 2,000)
3. Query with $search aggregation pipeline (cosmosSearch operator returns k-nearest neighbors)
4. Replicate across Azure regions for low-latency global access

**When to use**: Global applications with low-latency requirements (< 10ms) and document-oriented data model. Example: E-commerce product catalog with semantic search, replicated in US, EU, APAC.

**Considerations**: Vector dimensions limited to 2,000 (text-embedding-ada-002 is 1,536, fits). Cost is per vCore hour (~$0.50/hr for 2 vCores). Hybrid search requires manual implementation (separate text search + vector search).

### 3. PostgreSQL with pgvector (Cost-Effective Extension)

**What**: Open-source pgvector extension adds vector similarity search to existing PostgreSQL databases.

**How it works**:

1. Install pgvector extension (`CREATE EXTENSION vector`)
2. Add vector column to table (`ALTER TABLE products ADD COLUMN embedding vector(1536)`)
3. Create HNSW or IVF index for fast approximate nearest neighbor search
4. Query with distance operators: `<=>` (cosine), `<->` (L2), `<#>` (inner product)
5. Combine with SQL WHERE clauses for filtering, JOINs for relational data

**When to use**: Existing PostgreSQL infrastructure, budget constraints, or need for relational + vector queries. Example: Startup building RAG on top of current product database, avoiding separate vector store.

**Considerations**: Requires PostgreSQL expertise for tuning (HNSW parameters, VACUUM, index maintenance). Horizontal scaling needs sharding (e.g., Citus extension). Lower operational cost but higher self-management burden.

### 4. Redis with Vector Search (Low-Latency Cache)

**What**: In-memory data store with vector similarity search module (RediSearch).

**How it works**:

1. Define vector field schema (FT.CREATE with VECTOR type, HNSW algorithm)
2. Store vectors as hashes or JSON documents
3. Query with FT.SEARCH and KNN parameter (k-nearest neighbors)
4. Use TTL for automatic expiration (cache invalidation)

**When to use**: Low-latency requirements (< 1ms), ephemeral data, or caching frequently accessed embeddings. Example: Real-time recommendation engine serving personalized suggestions with sub-millisecond latency.

**Considerations**: In-memory cost ($$$ for large datasets). Persistence via AOF/RDB snapshots (trades off durability vs performance). Best for hot data (frequently accessed subset), cold data in durable store.

### 5. FAISS (In-Memory Prototyping)

**What**: Facebook AI Similarity Search library for in-process vector search, no external database.

**How it works**:

1. Initialize FAISS index in application memory (IndexHNSWFlat, IndexIVFFlat, etc.)
2. Add vectors with index.add() (numpy arrays)
3. Search with index.search(query_vector, k) returns distances and indices
4. Store metadata separately (FAISS only handles vectors, no filtering/documents)

**When to use**: Prototyping, research, Jupyter notebooks, or small datasets (< 1M vectors fitting in RAM). Example: Experimenting with different embedding models, testing RAG chunking strategies before production.

**Considerations**: No persistence (serialize to disk manually), no filtering (post-filter in application), no multi-user concurrency. Production requires migration to durable store (see code-examples.md #8 for migration pattern).

### 6. Pinecone / Weaviate / Qdrant (Managed Multi-Cloud)

**What**: Specialized managed vector databases with cloud-agnostic deployment and advanced features.

**How it works**:

- Pinecone: Serverless or pod-based, auto-scaling, metadata filtering, sparse-dense hybrid vectors
- Weaviate: GraphQL API, schema-based, built-in vectorization modules, multi-tenancy
- Qdrant: Open-source option, payload filtering, quantization (reduce memory), on-premise or cloud

**When to use**: Multi-cloud strategy, avoiding vendor lock-in, or advanced features (e.g., Weaviate's graph traversal, Qdrant's quantization). Example: Enterprise requiring same vector store across AWS, Azure, GCP.

**Considerations**: Additional vendor relationship, pricing models vary (Pinecone per index/query, Weaviate per pod, Qdrant open-source + paid cloud). Evaluate Azure-native options first (AI Search, Cosmos DB) for Azure-centric architectures.

## Quick Reference

| Use Case                   | Recommended Store        | Azure Services                      | Notes                              |
| -------------------------- | ------------------------ | ----------------------------------- | ---------------------------------- |
| Enterprise RAG             | Azure AI Search          | Search + OpenAI                     | Hybrid search, semantic ranking    |
| Global low-latency app     | Cosmos DB (vCore)        | Cosmos DB + OpenAI                  | Multi-region replication           |
| Existing PostgreSQL        | pgvector extension       | PostgreSQL Flexible Server + OpenAI | Cost-effective, relational+vector  |
| Real-time recommendations  | Redis vector search      | Cache for Redis + OpenAI            | Sub-ms latency, ephemeral          |
| Prototyping/research       | FAISS in-memory          | None (local library) + OpenAI       | Fast iteration, no infrastructure  |
| Multi-cloud or specialized | Pinecone/Weaviate/Qdrant | External service + OpenAI           | Vendor-agnostic, advanced features |

## Common Pitfalls

- **Using FAISS in production without considering persistence** → FAISS is in-memory only; application restart loses all data. Save index to disk or migrate to durable store (Azure AI Search, Cosmos DB, pgvector) before production. See code-examples.md #8 for migration.

- **Ignoring filtering performance in vector stores** → Post-filtering (search first, then filter) is 10-100x slower than pre-filtering (filter first, then search). Verify vector store supports efficient pre-filtering (Azure AI Search, Cosmos DB, pgvector support this; FAISS does not).

- **Over-provisioning managed services for dev/test** → Azure AI Search S1 tier (~$250/mo) is overkill for prototyping. Use Basic tier ($75/mo) or pgvector on PostgreSQL Burstable tier ($15/mo) for non-production workloads.

- **Not tuning HNSW parameters for workload** → Default M=16, efConstruction=400 balances speed and quality, but high-recall use cases need M=32, efConstruction=800 (slower indexing, higher memory, better recall). Test with your data and queries.

- **Mixing transactional and vector workloads incorrectly** → pgvector on PostgreSQL OLTP database can cause contention (vector queries are CPU-heavy). Consider read replicas for vector queries or separate vector store if transaction latency suffers.

- **Ignoring embedding dimension limits** → Cosmos DB max 2,000 dims (text-embedding-ada-002 is 1,536, OK). Azure AI Search max 3,072 dims. Check limits before choosing model (e.g., text-embedding-3-large is 3,072 dims, at Azure AI Search limit).

## Bundled Resources

- **Code Examples**: See `references/code-examples.md` for working implementations of each vector store (Azure AI Search, Cosmos DB, pgvector, Redis, FAISS) with Azure OpenAI embeddings.
- **Microsoft Learn**: See `references/microsoft-learn.md` for curated documentation on vector search in Azure services, pgvector extension, FAISS library, and third-party vector databases.
