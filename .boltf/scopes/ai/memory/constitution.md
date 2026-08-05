# BOLT Framework Project Constitution — Scope: AI

> **Extracted from**: `.boltf/memory/constitution.md`
> **Scope**: `ai` — AI/ML models, AI agents, prompt engineering, responsible AI, and model lifecycle.
> Articles marked with 🔄 are **common to all scopes** and always present.
> Sections marked with 🆕 are **proposed additions** not present in the original constitution.

---

## Preamble 🔄

This Constitution establishes the governing principles, technology decisions, and standards for the **[PROJECT_NAME]** project. All AI agents, developers, and automated systems MUST adhere to this document.

**This document is the SINGLE SOURCE OF TRUTH.**

**Cloud Provider**: Microsoft Azure (mandatory for all deployments)

---

## Article X: Environments & Configuration 🔄

> **📋 Applies to**: ALL project types

### Section 10.1: Environment Strategy

| Environment | Purpose                      | Enabled | Auto-Deploy              |
| ----------- | ---------------------------- | ------- | ------------------------ |
| **dev**     | Development, rapid iteration | [ ] Yes | [ ] On commit to develop |
| **uat**     | User Acceptance Testing      | [ ] Yes | [ ] On PR merge          |
| **pre**     | Pre-production, staging      | [ ] Yes | [ ] Manual trigger       |
| **prod**    | Production                   | [ ] Yes | [ ] Manual approval      |

### Section 10.2: Configuration Management

Select strategy:

- [ ] **Azure App Configuration** - Centralized, feature flags (recommended)
- [ ] **Environment Variables** - Container/App Service config
- [ ] **appsettings.{Environment}.json** (.NET) / **.env files** (Node.js)
- [ ] **Combination** - App Config + Key Vault (recommended)

### Section 10.3: Secrets Management

| Secret Type        | Storage         |
| ------------------ | --------------- |
| Connection Strings | Azure Key Vault |
| API Keys           | Azure Key Vault |
| Certificates       | Azure Key Vault |

Local Development Secrets:

- [ ] **User Secrets** (.NET) - `dotnet user-secrets`
- [ ] **.env files** (Node.js) - gitignored
- [ ] **Local Key Vault** - Azure Key Vault dev instance

### Section 10.4: Feature Flags

Feature Flag Provider:

- [ ] **None**
- [ ] **Azure App Configuration** - Native integration
- [ ] **LaunchDarkly** - Enterprise features
- [ ] **Unleash** - Open-source

---

## Article XI: CI/CD Pipeline 🔄

> **📋 Applies to**: ALL project types

### Section 11.1: CI/CD Platform

Select ONE:

- [ ] **GitHub Actions** - GitHub-native
- [ ] **Azure DevOps Pipelines** - Azure-native

### Section 11.2: Pipeline Stages

#### For Application Development

| Stage                  | Enabled | Threshold                          |
| ---------------------- | ------- | ---------------------------------- |
| **Build**              | [ ] Yes | Warnings as errors: [ ] Yes [ ] No |
| **Lint/Format**        | [ ] Yes | -                                  |
| **Unit Tests**         | [ ] Yes | Coverage >= \_\_%                  |
| **Integration Tests**  | [ ] Yes | -                                  |
| **Architecture Tests** | [ ] Yes | -                                  |
| **Mutation Tests**     | [ ] Yes | Score >= \_\_%                     |
| **Security Scan**      | [ ] Yes | 0 Critical                         |
| **Container Build**    | [ ] Yes | -                                  |
| **Container Scan**     | [ ] Yes | 0 Critical                         |

#### Deployment Stages

| Stage           | Enabled | Trigger            |
| --------------- | ------- | ------------------ |
| **Deploy Dev**  | [ ] Yes | Auto on develop    |
| **Deploy UAT**  | [ ] Yes | Auto on release/\* |
| **Deploy Pre**  | [ ] Yes | Manual trigger     |
| **Deploy Prod** | [ ] Yes | Manual approval    |

### Section 11.3: Deployment Strategy

Select ONE:

- [ ] **Rolling Update** - Gradual replacement
- [ ] **Blue-Green** - Azure Deployment Slots / K8s
- [ ] **Canary** - Gradual traffic shift
- [ ] **Feature Flags** - Deploy dark, enable via flags

### Section 11.4: Branch Strategy

Select ONE:

- [ ] **GitFlow** - feature/, develop, release/, main
- [ ] **GitHub Flow** - feature/, main
- [ ] **Trunk-Based** - Short-lived branches, main

---

## Article XII: Observability 🔄

> **📋 Applies to**: ALL project types

### Section 12.1: Observability Strategy

Select ONE:

- [ ] **Azure-Native** - Azure Monitor + Application Insights
- [ ] **OpenTelemetry → Azure** - OTel SDK → Azure Monitor Exporter
- [ ] **OpenTelemetry → Grafana Stack** - Self-hosted Grafana/Loki/Tempo

### Section 12.2: Health Checks

```text
/health       - Full health check
/health/ready - Readiness probe
/health/live  - Liveness probe
```

---

## Article XIII: AI Architecture & Platform Strategy

> **📋 Applies to**: AI & Machine Learning projects, Generative AI applications, RAG systems
> **⏭️ Skip if**: Pure infrastructure-only project with no AI/ML components
> **Priority**: Must be decided BEFORE implementing AI features, model training, or RAG systems

### Section 13.1: AI Architecture Pattern 🔴 CRITICAL

> **🔴 CRITICAL**: AI architecture choice (MLOps vs RAG vs Pre-built) fundamentally determines project scope and complexity

Select ONE primary pattern (or multiple for hybrid):

- [ ] **MLOps with Azure Machine Learning** - Full ML lifecycle management
  - **Best for**: Custom predictive models, traditional ML (classification, regression, forecasting)
  - **Includes**: Training pipelines, model registry, experiment tracking, managed endpoints
  - **Use cases**: Credit scoring, demand forecasting, recommendation engines, anomaly detection

- [ ] **RAG (Retrieval Augmented Generation)** - Grounded LLM responses with organizational knowledge
  - **Best for**: Knowledge base Q&A, document search, contextual chat applications
  - **Includes**: Azure OpenAI + Vector Store + Document Processing
  - **Use cases**: Internal knowledge assistant, document Q&A, customer support chatbot

- [ ] **Pre-built AI Services** - Cognitive Services for standard AI capabilities
  - **Best for**: Standard AI features without custom training (OCR, translation, speech)
  - **Includes**: Azure AI Vision, Speech, Language, Document Intelligence, Translator
  - **Use cases**: Document digitization, sentiment analysis, image classification, transcription

- [ ] **Custom ML Models** - Traditional machine learning with Python SDK
  - **Best for**: Unique business problems requiring custom feature engineering
  - **Includes**: Jupyter notebooks, AutoML, scikit-learn, PyTorch, TensorFlow
  - **Use cases**: Churn prediction, time series forecasting, image segmentation

- [ ] **Hybrid AI Architecture** - Multi-service orchestration
  - **Best for**: Complex workflows combining multiple AI capabilities
  - **Includes**: Azure OpenAI + Custom ML + Cognitive Services + Orchestration
  - **Use cases**: Intelligent document processing (OCR → Summarization → Classification)

- [ ] **Prompt Engineering & Orchestration** - LLM workflow management
  - **Best for**: Complex LLM chains, agent architectures, tool-calling patterns
  - **Includes**: Prompt Flow, LangChain, Semantic Kernel, multi-step reasoning
  - **Use cases**: Research assistant, data analysis agent, workflow automation

### Section 13.2: ML Training Strategy 🟡 IMPORTANT

> **📋 Applies to**: Projects requiring custom ML models (skip if using only pre-built services or OpenAI)
> **🟡 IMPORTANT**: Training approach affects timelines and expertise required but has reasonable defaults

Select ONE:

- [ ] **AutoML** - Automated feature engineering, algorithm selection, hyperparameter tuning
  - **Best for**: Quick prototypes, teams without deep ML expertise
  - **Azure Service**: Azure Machine Learning AutoML
  - **Training time**: 15 min - 2 hours (depending on compute)

- [ ] **Custom Training (Python SDK)** - Full control over model architecture
  - **Best for**: Specific model requirements, advanced ML teams
  - **Azure Service**: Azure ML Workspaces + Compute Clusters
  - **Frameworks**: scikit-learn, PyTorch, TensorFlow, XGBoost

- [ ] **Transfer Learning** - Pre-trained models + fine-tuning on domain data
  - **Best for**: Computer vision, NLP with limited training data
  - **Azure Service**: Azure ML Model Catalog (Hugging Face, ONNX, PyTorch Hub)
  - **Examples**: Fine-tune BERT for custom NER, ResNet for specialized image classification

- [ ] **Fine-tuning Azure OpenAI** - Customize GPT models with proprietary data
  - **Best for**: Domain-specific language patterns, custom writing styles
  - **Azure Service**: Azure OpenAI Fine-tuning (GPT-3.5-Turbo, Babbage-002)
  - **Training data**: Minimum 50 examples (recommended 500+)

- [ ] **No Training** - Use only pre-built services or foundation models as-is
  - **Best for**: Standard AI capabilities, proof-of-concept projects
  - **Azure Services**: Azure OpenAI GPT-4o, Cognitive Services

### Section 13.3: AI Service Selection 🔴 CRITICAL

> **📋 Applies to**: ALL AI projects
> **🔴 CRITICAL**: Which Azure AI services to use determines architecture and cost structure

Select ALL applicable services:

- [ ] **Azure Machine Learning** - Full ML platform (training, deployment, monitoring)
  - **When**: Custom models, MLOps pipelines, batch/real-time inference
  - **Pricing**: Pay for compute (CPU/GPU hours), storage, endpoints

- [ ] **Azure OpenAI Service** - Managed GPT-4o, GPT-4, GPT-3.5-Turbo, Embeddings
  - **When**: Chat, completions, text generation, embeddings for RAG
  - **Pricing**: Pay per token (input + output), provisioned throughput available

- [ ] **Azure AI Search** - Vector and hybrid search engine
  - **When**: RAG architecture, semantic search, knowledge base indexing
  - **Pricing**: Per search unit, storage, queries per second

- [ ] **Azure Cognitive Services** - Pre-built AI APIs
  - **Services**: Vision (OCR, image analysis), Speech (STT/TTS), Language (sentiment, NER), Document Intelligence
  - **When**: Standard AI capabilities without custom training
  - **Pricing**: Pay per API call (tiered discounts available)

- [ ] **Azure AI Foundry** - Model catalog, prompt flow, evaluation tools
  - **When**: Rapid prototyping, model comparison, prompt engineering
  - **Included**: Access to 1,600+ models from Microsoft, Meta, Mistral, Cohere

### Section 13.4: Inference Deployment Pattern 🟡 IMPORTANT

> **📋 Applies to**: Projects deploying custom ML models (not applicable to API-only services)
> **🟡 IMPORTANT**: Deployment pattern affects latency and cost but can be adjusted later

Select ONE primary pattern:

- [ ] **Managed Online Endpoints** - Real-time inference with auto-scaling
  - **Latency**: <100ms typical
  - **Best for**: Real-time predictions, interactive applications
  - **Features**: Blue-green deployment, A/B testing, traffic splitting, auto-scale
  - **Cost**: Always-on compute (per VM hour)

- [ ] **Batch Endpoints** - Scheduled scoring on large datasets
  - **Latency**: Minutes to hours
  - **Best for**: Daily scoring jobs, data pipeline integration, cost optimization
  - **Features**: Parallel processing, scheduled triggers, Event Grid integration
  - **Cost**: Pay only for job execution time

- [ ] **Serverless Inference** - Pay-per-use, no infrastructure management
  - **Latency**: 100-500ms (includes cold start)
  - **Best for**: Unpredictable traffic, proof-of-concept, low-frequency inference
  - **Features**: Auto-scale to zero, pay per request
  - **Cost**: Per invocation (no minimum)

- [ ] **Container Instances (ACI)** - Custom runtime with full control
  - **Latency**: Configurable (depends on container specs)
  - **Best for**: Specialized runtimes, legacy models, custom dependencies
  - **Features**: Full Docker support, custom health checks
  - **Cost**: Per vCPU and memory allocation

- [ ] **Edge Deployment** - On-device inference (IoT, offline scenarios)
  - **Latency**: <10ms (local processing)
  - **Best for**: IoT devices, low-latency requirements, offline operation
  - **Features**: ONNX Runtime, model quantization, Azure IoT Edge integration
  - **Cost**: Device compute only (no cloud inference cost)

### Section 13.5: Vector Store & Embeddings (RAG Enablement) 🔴 CRITICAL

> **📋 Applies to**: RAG (Retrieval Augmented Generation) architectures ONLY
> **⏭️ Skip if**: No RAG, no semantic search, no vector embeddings
> **🔴 CRITICAL**: Vector store choice is hard to migrate later (data model and queries tightly coupled)

Select ONE vector store:

- [ ] **Azure AI Search** - Hybrid search (vectors + keywords) with semantic ranking
  - **Best for**: Enterprise RAG, multi-modal search (text + vectors), rich filtering
  - **Features**: Integrated vectorization, semantic ranking, knowledge mining pipelines
  - **Max vectors**: 50M per index (single replica)
  - **Pricing**: Per search unit + storage

- [ ] **Azure Cosmos DB (NoSQL + Vector Extension)** - Transactional database + vectors
  - **Best for**: Operational RAG (user data + semantic search), global distribution
  - **Features**: Multi-region replication, consistency models, vector indexing
  - **Max vectors**: Unlimited (distributed partitions)
  - **Pricing**: Per RU + storage

- [ ] **Redis Enterprise (RediSearch + Vector Similarity)** - In-memory vectors
  - **Best for**: Ultra-low latency (<10ms), high-throughput search
  - **Features**: In-memory performance, real-time indexing
  - **Max vectors**: 100M+ (depends on memory)
  - **Pricing**: Per memory allocation

- [ ] **Pinecone** - Managed vector database (SaaS)
  - **Best for**: Quick RAG prototypes, no infrastructure management
  - **Features**: Managed service, metadata filtering, namespaces
  - **Max vectors**: Unlimited (managed service)
  - **Pricing**: Per pod (storage + compute combined)

- [ ] **None** - No RAG architecture

**Embedding Model**:

- [ ] **Azure OpenAI text-embedding-ada-002** - 1536 dimensions, optimized for English
- [ ] **Azure OpenAI text-embedding-3-small** - 512-1536 dimensions, multilingual
- [ ] **Azure OpenAI text-embedding-3-large** - 256-3072 dimensions, highest accuracy
- [ ] **Azure AI Search Integrated Vectorization** - Built-in chunking + embeddings
- [ ] **Custom embedding model** - E5, BGE, or domain-specific embeddings

### Section 13.6: Prompt Engineering & Orchestration 🟡 IMPORTANT

> **📋 Applies to**: Projects using Azure OpenAI, GPT models, or LLM chains
> **🟡 IMPORTANT**: Orchestration framework affects development patterns but not architecture

Select ONE orchestration framework:

- [ ] **Prompt Flow (Azure AI Foundry)** - Visual designer for LLM workflows
  - **Best for**: Low-code/no-code teams, visual debugging, Azure-native integration
  - **Features**: Flow tracing, evaluation metrics, A/B testing, deployment to Azure
  - **Languages**: Python, .NET (via SDK)

- [ ] **LangChain** - Python/JavaScript orchestration framework
  - **Best for**: Complex agent architectures, tool calling, memory management
  - **Features**: 100+ integrations, agent types (ReAct, Self-Ask, Plan-and-Execute)
  - **Community**: Large open-source ecosystem

- [ ] **Semantic Kernel (Microsoft)** - .NET/Python/Java SDK for AI orchestration
  - **Best for**: Enterprise .NET applications, plugin architecture, function calling
  - **Features**: Planners, memory connectors, native function integration
  - **Integration**: Deep Azure OpenAI integration

- [ ] **Manual (Direct API Calls)** - No orchestration framework
  - **Best for**: Simple chat applications, single-turn completions
  - **Approach**: Direct Azure OpenAI SDK calls, custom retry logic

**Prompt Management**:

- [ ] **Prompt Registry** - Versioned prompt templates in Git + Azure App Configuration
- [ ] **Inline Prompts** - Hardcoded in application code
- [ ] **Prompt Flow Studio** - Manage prompts in Azure AI Foundry UI

### Section 13.7: Model Governance & MLOps 🟡 IMPORTANT

> **📋 Applies to**: Projects with custom ML models or multiple model versions
> **🟡 IMPORTANT**: Model governance is critical for production but tooling can evolve

Select ONE model registry:

- [ ] **Azure ML Model Registry** - Centralized, versioned, RBAC-enabled
  - **Best for**: Enterprise MLOps, model lineage tracking, compliance requirements
  - **Features**: Model versioning, tags/metadata, deployment history, audit logs
  - **Integration**: Azure ML Pipelines, endpoints

- [ ] **MLflow Tracking** - Open-source experiment logging + model tracking
  - **Best for**: ML research, experiment comparison, platform-agnostic
  - **Features**: Experiment runs, parameter logging, artifact storage
  - **Integration**: Can log to Azure ML backend

- [ ] **Git-based (NOT RECOMMENDED for production)** - Model files in repository
  - **Risk**: Large binary files, no versioning for artifacts, no audit trail
  - **Use only for**: Proof-of-concept, local development

- [ ] **None** - Manual model governance

**CI/CD for ML Pipelines**:

- [ ] **Azure DevOps + Azure ML Pipelines** - Integrated MLOps
- [ ] **GitHub Actions + Azure ML CLI v2** - Git-native automation
- [ ] **Manual** - No automated retraining/deployment

### Section 13.8: Responsible AI Practices 🟡 IMPORTANT

> **📋 Applies to**: ALL AI projects (mandatory for production deployments)
> **🟡 IMPORTANT**: Responsible AI is critical for compliance but practices can be added incrementally

Select ALL applicable practices (minimum 3 required for production):

- [ ] **Fairness Dashboard** - Bias detection across demographic groups
  - **Tool**: Microsoft Fairness 360, Fairlearn
  - **Metrics**: Demographic parity, equalized odds, disparate impact
  - **When**: Any model making decisions impacting people (hiring, lending, healthcare)

- [ ] **Interpretability (SHAP/LIME)** - Model explainability
  - **Tool**: InterpretML, SHAP library
  - **Output**: Feature importance, local explanations for predictions
  - **When**: Regulated industries (finance, healthcare), high-stakes decisions

- [ ] **Model Monitoring** - Drift detection, performance degradation
  - **Tool**: Azure ML Model Monitor, Evidently AI
  - **Metrics**: Data drift, model drift, prediction distribution
  - **Alerts**: Trigger retraining when drift exceeds threshold

- [ ] **Model Cards** - Document model behavior, limitations, intended use
  - **Format**: Markdown document in model registry
  - **Content**: Training data, performance metrics, known limitations, ethical considerations
  - **Audience**: Data scientists, compliance teams, end users

- [ ] **Datasheets for Datasets** - Document training data provenance
  - **Content**: Data sources, collection methodology, known biases, privacy considerations
  - **Purpose**: Reproducibility, transparency, compliance

- [ ] **Azure AI Content Safety** - Real-time content moderation (text + images)
  - **Protections**: Hate speech, violence, self-harm, sexual content
  - **Severity levels**: Safe, Low, Medium, High (configurable thresholds)
  - **When**: **MANDATORY** for any user-facing generative AI feature

- [ ] **Human-in-the-Loop (HITL)** - Human review for high-stakes predictions
  - **Pattern**: AI suggests → Human reviews → Human approves/rejects
  - **When**: Medical diagnosis, legal decisions, financial approvals

- [ ] **Prompt Injection Protection** - Mitigate adversarial prompts
  - **Techniques**: System prompt hardening, input/output validation, Azure AI Content Safety
  - **When**: User-provided prompts in production applications

### Section 13.9: Trade-offs and Rationale

> This section provides comparative analysis to guide architecture decisions.

#### 13.9.1: MLOps (Azure ML) vs Pre-built Services (Cognitive Services)

| Factor               | MLOps (Azure ML)                                                 | Pre-built Services (Cognitive Services)           |
| -------------------- | ---------------------------------------------------------------- | ------------------------------------------------- |
| **Time to Value**    | ⚠️ Weeks to months (data prep, training, evaluation)             | ✅ Hours to days (API integration)                |
| **Accuracy**         | ✅ Optimized for your data (90%+ achievable)                     | ⚠️ General-purpose (70-85% typical)               |
| **Customization**    | ✅ Full control (features, algorithms, hyperparameters)          | ⚠️ Limited (API parameters only)                  |
| **Cost (training)**  | ⚠️ $200-$5,000/month (compute clusters, storage)                 | ✅ $0 (no training cost)                          |
| **Cost (inference)** | ⚠️ $100-$2,000/month (always-on endpoints or batch jobs)         | ✅ Pay-per-call ($1-$3 per 1,000 transactions)    |
| **Expertise**        | ⚠️ Requires data scientists, ML engineers                        | ✅ Requires only developers (API integration)     |
| **Best for**         | Unique business problems, high-value predictions, data available | Standard AI capabilities (OCR, translation, etc.) |

**Recommendation**: Start with pre-built services for POCs. Invest in MLOps when accuracy gains justify the cost (high-value use cases like fraud detection, personalized recommendations).

#### 13.9.2: RAG (Azure OpenAI) vs Fine-tuning Custom Model

| Factor               | RAG (Retrieval Augmented Generation)                         | Fine-tuning Azure OpenAI                            |
| -------------------- | ------------------------------------------------------------ | --------------------------------------------------- |
| **Use Case**         | ✅ Knowledge base Q&A, document search, contextual answers   | ⚠️ Domain-specific language patterns, custom styles |
| **Training Data**    | ✅ No training (uses documents as-is)                        | ⚠️ Minimum 50 examples (500+ recommended)           |
| **Cost (setup)**     | ⚠️ Vector store + embeddings ($50-$500/month)                | ✅ One-time training cost ($5-$50 per job)          |
| **Cost (inference)** | ⚠️ Higher (prompt + embeddings + completion = 3x token cost) | ✅ Lower (no retrieval overhead)                    |
| **Accuracy**         | ✅ Grounded in source documents (citable, auditable)         | ⚠️ Depends on training data quality                 |
| **Hallucination**    | ✅ Lower (grounded in retrieved facts)                       | ⚠️ Higher (model generates from learned patterns)   |
| **Update Frequency** | ✅ Real-time (add documents to index immediately)            | ⚠️ Requires retraining (weeks to update model)      |
| **Transparency**     | ✅ Can show source citations                                 | ⚠️ Black-box model behavior                         |
| **Best for**         | Dynamic knowledge bases, compliance-driven industries        | Static domain language (medical terminology, etc.)  |

**Recommendation**: Default to RAG for knowledge-based applications. Use fine-tuning ONLY if you need specific writing styles or terminology that RAG cannot capture.

#### 13.9.3: Real-time Endpoints vs Batch Endpoints

| Factor               | Managed Online Endpoints (Real-time)          | Batch Endpoints                                   |
| -------------------- | --------------------------------------------- | ------------------------------------------------- |
| **Latency**          | ✅ <100ms                                     | ⚠️ Minutes to hours                               |
| **Throughput**       | ⚠️ 100-1,000 requests/sec (depends on VM)     | ✅ Millions of rows per job (parallel processing) |
| **Cost**             | ⚠️ Always-on ($200-$2,000/month per endpoint) | ✅ Pay only for job execution ($10-$100 per job)  |
| **Auto-scaling**     | ✅ Scale based on traffic                     | ❌ Fixed parallelism per job                      |
| **Best for**         | Interactive apps, chatbots, real-time scoring | Daily scoring pipelines, bulk processing          |
| **Example use case** | Credit card fraud detection (instant)         | Customer churn scoring (daily batch)              |

**Recommendation**: Use real-time endpoints for user-facing applications (<500ms requirement). Use batch endpoints for backoffice analytics, daily reports, data pipeline integration.

#### 13.9.4: Prompt Flow vs LangChain

| Factor                | Prompt Flow (Azure AI Foundry)                 | LangChain                                         |
| --------------------- | ---------------------------------------------- | ------------------------------------------------- |
| **Learning Curve**    | ✅ Low (visual designer, no-code/low-code)     | ⚠️ Medium-High (Python/JS code, abstractions)     |
| **Debugging**         | ✅ Built-in tracing, visual flow execution     | ⚠️ Manual instrumentation (LangSmith recommended) |
| **Azure Integration** | ✅ Native (Azure OpenAI, AI Search, Key Vault) | ⚠️ Requires custom connectors                     |
| **Flexibility**       | ⚠️ Limited to supported node types             | ✅ Highly extensible (100+ integrations)          |
| **Community**         | ⚠️ Smaller (Microsoft ecosystem)               | ✅ Large open-source community                    |
| **Agent Support**     | ⚠️ Basic (custom Python nodes required)        | ✅ Built-in (ReAct, Self-Ask, Plan-and-Execute)   |
| **Best for**          | Azure-native teams, visual debugging           | Complex agents, multi-framework integration       |

**Recommendation**: Use Prompt Flow for Azure-centric projects with low-code requirements. Use LangChain if you need advanced agent patterns or multi-cloud portability.

#### 13.9.5: Azure AI Search vs Cosmos DB (Vector Store)

| Factor                  | Azure AI Search                                   | Azure Cosmos DB (NoSQL + Vectors)              |
| ----------------------- | ------------------------------------------------- | ---------------------------------------------- |
| **Primary Purpose**     | ✅ Search engine with vector capabilities         | ⚠️ Transactional database with vector indexing |
| **Hybrid Search**       | ✅ Native (vectors + keywords + semantic ranking) | ⚠️ Manual implementation                       |
| **Max Vectors**         | ⚠️ 50M per index (single replica)                 | ✅ Unlimited (distributed partitions)          |
| **Latency**             | ⚠️ 50-200ms (typical)                             | ✅ <10ms (transactional queries)               |
| **Global Distribution** | ❌ Regional deployments only                      | ✅ Multi-region replication (5-way writes)     |
| **Cost**                | ⚠️ $250-$2,500/month (depends on search units)    | ⚠️ $200-$5,000/month (depends on RU + storage) |
| **Best for**            | Pure search/RAG workloads, document indexing      | Operational apps (user data + semantic search) |

**Recommendation**: Use Azure AI Search for RAG applications focused on search/retrieval. Use Cosmos DB if you need operational database + semantic search in one service (e.g., user profiles with vector similarity).

### Section 13.10: References & Resources

> Official Microsoft Learn documentation for Azure AI architecture patterns

#### Azure Machine Learning & MLOps

- [MLOps v2 Architecture with Azure Machine Learning](https://learn.microsoft.com/azure/architecture/ai-ml/guide/machine-learning-operations-v2)
- [Train models in Azure Machine Learning](https://learn.microsoft.com/azure/machine-learning/concept-train-machine-learning-model)
- [Deploy models with managed online endpoints](https://learn.microsoft.com/azure/machine-learning/concept-endpoints-online)
- [Batch inference with Azure ML](https://learn.microsoft.com/azure/machine-learning/concept-endpoints-batch)

#### Azure OpenAI & RAG

- [Retrieval Augmented Generation (RAG) in Azure OpenAI](https://learn.microsoft.com/azure/ai-services/openai/concepts/use-your-data)
- [Azure OpenAI Service](https://learn.microsoft.com/azure/ai-services/openai/overview)
- [Prompt engineering techniques](https://learn.microsoft.com/azure/ai-services/openai/concepts/advanced-prompt-engineering)
- [Fine-tune Azure OpenAI models](https://learn.microsoft.com/azure/ai-services/openai/how-to/fine-tuning)

#### Azure AI Search

- [Vector search in Azure AI Search](https://learn.microsoft.com/azure/search/vector-search-overview)
- [Hybrid search (vectors + keywords)](https://learn.microsoft.com/azure/search/hybrid-search-overview)
- [Semantic ranking](https://learn.microsoft.com/azure/search/semantic-search-overview)

#### Responsible AI

- [Microsoft Responsible AI Standard v2](https://www.microsoft.com/ai/responsible-ai)
- [Azure AI Content Safety](https://learn.microsoft.com/azure/ai-services/content-safety/overview)
- [Fairness assessment with Fairlearn](https://learn.microsoft.com/azure/machine-learning/how-to-machine-learning-fairness-aml)
- [Model interpretability in Azure ML](https://learn.microsoft.com/azure/machine-learning/how-to-machine-learning-interpretability)

#### Prompt Flow & Orchestration

- [Prompt Flow in Azure AI Foundry](https://learn.microsoft.com/azure/ai-studio/how-to/prompt-flow)
- [LangChain with Azure OpenAI](https://python.langchain.com/docs/integrations/platforms/microsoft)
- [Semantic Kernel (Microsoft)](https://learn.microsoft.com/semantic-kernel/overview/)

#### Azure AI Foundry

- [Azure AI Foundry documentation](https://learn.microsoft.com/azure/ai-studio/)
- [Model catalog (1,600+ models)](https://learn.microsoft.com/azure/ai-studio/how-to/model-catalog)
- [Evaluation of generative AI applications](https://learn.microsoft.com/azure/ai-studio/concepts/evaluation-metrics-built-in)

---

## Article XIV: Multi-Agent Architectures & Orchestration

> **📋 Applies to**: AI projects requiring multi-agent coordination, complex workflows, cross-domain tasks
> **⏭️ Skip if**: Single-agent solutions are sufficient for your use case
> **References**: [AI agent orchestration patterns (Microsoft)](https://learn.microsoft.com/azure/architecture/ai-ml/guide/ai-agent-design-patterns)

**Multi-Agent Systems** use multiple specialized AI agents to break down complex problems into units of work, each handled by dedicated agents with specific capabilities. This approach mirrors human teamwork and provides specialization, scalability, maintainability, and optimization advantages over monolithic single-agent solutions.

### Section 14.1: When to Use Multi-Agent Architecture 🟡 IMPORTANT

> **🟡 IMPORTANT**: Multi-agent decision affects complexity but can start simple and evolve

**Start with Single Agent** - Most scenarios benefit from one agent with tools/knowledge. Use multi-agent ONLY when:

1. **Security & Compliance Boundaries** - Regulations mandate strict data isolation (e.g., different security classifications)
2. **Multiple Teams Involved** - Distinct teams manage separate knowledge areas with independent development cycles
3. **Future Growth Planned** - Roadmap includes diverse features spanning 3+ distinct functional domains
4. **Cross-Functional Problems** - Tasks require distinct specializations that can't be combined (e.g., legal + technical + creative analysis)

**Decision Tree**:

```text
Can single agent + tools solve it?
├─ Yes → Use single agent (simpler, lower latency)
└─ No → Are there security/compliance boundaries?
    ├─ Yes → Use multi-agent (mandatory separation)
    └─ No → Can single agent handle complexity?
        ├─ Yes → Use single agent
        └─ No → Use multi-agent (proven scalability limits)
```

### Section 14.2: Multi-Agent Orchestration Patterns 🟢 LOW-PRIO

> **🟢 LOW-PRIO**: Orchestration patterns can be adjusted as requirements evolve

Select ONE or COMBINE patterns based on workflow requirements:

#### Pattern 1: Sequential Orchestration

**Description**: Agents execute in a defined order, each building on the previous agent's output (pipeline pattern).

**When to use**:

- Tasks require cumulative context or specific order (document approval workflows)
- Output of Agent N is input to Agent N+ 1
- Deterministic, reproducible results required

**Example**: Legal contract review → Financial analysis → Risk assessment → Executive summary

**Implementation**:

```python
# Microsoft Agent Framework - Sequential
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import RoundRobinGroupChat

agents = [legal_agent, finance_agent, risk_agent, summary_agent]
team = RoundRobinGroupChat(agents, max_turns=4)
result = await team.run(task="Review acquisition contract")
```

#### Pattern 2: Concurrent Orchestration (Fan-out/Fan-in)

**Description**: Multiple agents work in parallel on the same task, results are aggregated.

**When to use**:

- Tasks benefit from multiple independent perspectives (ensemble reasoning)
- Time-sensitive scenarios requiring parallel processing
- Voting/consensus decisions (majority rule, quorum)

**Example**: Stock analysis by Technical Analyst + Fundamental Analyst + Sentiment Analyst → Aggregated recommendation

**Implementation**:

```python
# Concurrent execution
agents = [technical_agent, fundamental_agent, sentiment_agent]
results = await asyncio.gather(*[agent.run(task) for agent in agents])
final_recommendation = aggregate_results(results, strategy="weighted_average")
```

#### Pattern 3: Group Chat (Collaborative)

**Description**: Peer-to-peer agent communication, agents decide dynamically who speaks next.

**When to use**:

- Collaborative problem-solving requiring back-and-forth discussion
- No predefined speaker order; agents "self-organize"
- Brainstorm, debate, or multi-perspective analysis

**Example**: Product design brainstorm with UX designer + Engineer + Marketing agents

**Implementation**:

```python
# Microsoft Agent Framework - Group Chat
from autogen_agentchat.teams import SelectorGroupChat

team = SelectorGroupChat(
    participants=[ux_agent, engineer_agent, marketing_agent],
    model_client=selector_model  # LLM decides who speaks next
)
result = await team.run(task="Design new feature")
```

#### Pattern 4: Handoff (Escalation/Transfer)

**Description**: Agent transfers conversation to another agent based on conditions (triage pattern).

**When to use**:

- Customer support escalation (tier 1 → tier 2 → human)
- Task routing based on complexity or domain
- Agent recognizes it can't handle request

**Example**: Customer service bot → Technical support agent → Billing specialist

**Implementation**:

```python
# Handoff pattern
if user_intent == "billing_issue":
    await chatbot_agent.handoff_to(billing_agent)
elif complexity_score > THRESHOLD:
    await chatbot_agent.handoff_to(specialist_agent)
```

#### Pattern 5: Magentic (Dynamic Planning)

**Description**: Manager agent dynamically creates a plan and assigns tasks to worker agents.

**When to use**:

- Tasks are too complex or varied for fixed orchestration
- Decomposition into sub-tasks benefits from LLM reasoning
- Unknown task structure at design time

**Example**: "Research market trends for Q1 2026" → Manager decomposes into: data collection, statistical analysis, report writing

**Warning**: Most expensive pattern (manager iterates until viable plan), unpredictable cost.

### Section 14.3: Agent Framework Selection

Select ONE primary framework:

#### Option 1: Microsoft Agent Framework (Recommended for Azure)

- **Best for**: Azure-native multi-agent systems, enterprise support
- **Languages**: Python, .NET (C#)
- **Features**:
  - Built-in orchestration patterns (Sequential, Concurrent, Group Chat, Handoff, Magentic)
  - Human-in-the-loop support
  - Native Azure OpenAI integration
  - Workflow declarative YAML + code combinations
- **Migration**: Successor to Semantic Kernel agents
- **Repository**: [github.com/microsoft/agent-framework](https://github.com/microsoft/agent-framework)

**Example**:

```python
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_ext.models.openai import AzureOpenAIChatCompletionClient

# Define agents
researcher = AssistantAgent(
    name="Researcher",
    model_client=AzureOpenAIChatCompletionClient(...),
    system_message="You research market trends.",
    tools=[web_search_tool]
)

writer = AssistantAgent(
    name="Writer",
    model_client=AzureOpenAIChatCompletionClient(...),
    system_message="You write executive summaries."
)

# Sequential orchestration
team = RoundRobinGroupChat([researcher, writer])
result = await team.run(task="Research AI trends and write summary")
```

#### Option 2: Semantic Kernel (Agents Module)

- **Best for**: .NET-first teams, existing Semantic Kernel investments
- **Languages**: C#, Python, Java
- **Features**:
  - Agent orchestration via `ChatCompletionAgent`, `OpenAIAssistantAgent`
  - Function calling, plugins, planners
  - Tight integration with Azure OpenAI Assistants API
- **Status**: Continues to be supported for agent scenarios; Microsoft Agent Framework adds higher-level workflows

**Example**:

```csharp
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Agents;

var kernel = Kernel.CreateBuilder()
    .AddAzureOpenAIChatCompletion(...)
    .Build();

ChatCompletionAgent agent = new(kernel, "ResearchAgent") {
    Instructions = "You research market trends."
};

await agent.InvokeAsync("What are AI trends in 2026?");
```

#### Option 3: LangChain / LangGraph

- **Best for**: Multi-cloud, Python-native teams, complex agent graphs
- **Languages**: Python, JavaScript
- **Features**:
  - 100+ integrations (Azure OpenAI, AWS Bedrock, Google Vertex)
  - Advanced agent types (ReAct, Self-Ask, Plan-and-Execute)
  - LangGraph for stateful multi-agent workflows
- **Community**: Large open-source ecosystem

**Trade-off**: Not Azure-native; requires custom connectors for Azure services.

#### Option 4: Azure AI Foundry Agent Service (Low-Code)

- **Best for**: No-code/low-code teams, simple workflows
- **Languages**: UI-driven (REST APIs available)
- **Features**:
  - Managed service for connected agents
  - Built-in monitoring, deployment pipelines
  - Limited to nondeterministic orchestrations
- **Limitation**: Cannot fully implement deterministic patterns (Sequential, Concurrent)

**Recommendation**: Use Agent Framework (Python/.NET) for full orchestration control. Use Foundry Agent Service for simple managed scenarios.

### Section 14.4: State Management Across Agents

**Context Sharing Strategies**:

- [ ] **Shared Memory (In-Memory)** - Fast, but lost on restart (dev only)
- [ ] **Persistent State Store** - Azure Cosmos DB, Redis (recommended for production)
- [ ] **Message Passing** - Agents communicate via messages (stateless agents)
- [ ] **Checkpointing** - Persist state at workflow milestones (fault tolerance)

**State Scope**: Minimize shared state to reduce token overhead and privacy risk.

**Example** (Persistent state with Cosmos DB):

```python
from azure.cosmos import CosmosClient

# Store conversation state
conversation_state = {
    "conversation_id": "conv-123",
    "current_agent": "researcher",
    "context": { "topic": "AI trends", "sources": [...] }
}

cosmos_client.upsert_item(conversation_state)
```

### Section 14.5: Human-in-the-Loop (HITL)

**HITL Integration Points**:

- [ ] **Approval gates** - Require human approval before agent proceeds (e.g., sending email, making purchase)
- [ ] **Escalation** - Agent transfers to human when confidence is low
- [ ] **Feedback loops** - Human provides feedback, agent refines output
- [ ] **Observer mode** - Human monitors group chat (read-only)

**Implementation**: Mandatory gates make orchestration synchronous. Persist state at checkpoints to allow resumption.

**Example**:

```python
# Approval gate for high-stakes actions
if action.type == "send_contract":
    approval = await request_human_approval(action)
    if not approval.approved:
        return "Action declined by human reviewer"
```

### Section 14.6: Multi-Agent Testing & Validation

**Testing Strategies**:

- [ ] **Unit tests per agent** - Test individual agent logic in isolation
- [ ] **Integration tests** - Test orchestration patterns end-to-end
- [ ] **LLM-as-Judge evaluation** - Use GPT-4 to score multi-agent outputs (non-deterministic results)
- [ ] **Replay tests** - Record agent interactions, replay for regression testing

**Evaluation Metrics**:

| Metric                   | Description                            | Tool                 |
| ------------------------ | -------------------------------------- | -------------------- |
| **Task completion rate** | % of workflows that succeed end-to-end | Custom logging       |
| **Latency per agent**    | Time spent in each agent               | Azure Monitor        |
| **Token consumption**    | Cost per orchestration pattern         | Application Insights |
| **Handoff accuracy**     | % of correct agent transitions         | LLM-as-judge         |

### Section 14.7: Cost Optimization for Multi-Agent Systems

**Cost Drivers**:

1. **Model invocations multiply** - Each agent calls a model (1 workflow = N agent calls)
2. **Context accumulation** - Context windows grow as agents pass information
3. **Concurrent patterns spike usage** - Parallel agents invoke models simultaneously

**Optimization Strategies**:

- [ ] **Use smaller models per agent** - Not every agent needs GPT-4 (e.g., classification agent can use GPT-3.5-Turbo)
- [ ] **Context compaction** - Summarize previous agent outputs before passing to next agent
- [ ] **Batching** - Group multiple user requests into single orchestration run
- [ ] **Caching** - Cache agent responses for repeated queries (Redis, Azure AI Search)
- [ ] **Monitor per-agent cost** - Identify expensive agents, optimize prompts/tools

**Example** (Context compaction):

```python
# Instead of passing full 5,000-token context
full_context = agent1.run(task)

# Compress to summary
summary = summarize(full_context, max_tokens=500)
agent2.run(summary)  # Reduced token cost
```

### Section 14.8: Multi-Agent Observability

**Instrumentation Requirements**:

- [ ] **Trace agent interactions** - Log every agent invocation, tool call, handoff
- [ ] **Visualize orchestration flow** - Diagram which agents executed, in what order
- [ ] **Monitor performance per agent** - Latency, token usage, error rate
- [ ] **Distributed tracing** - Use OpenTelemetry to trace requests across agents

**Tools**:

- **Application Insights** - Azure-native telemetry for agent monitoring
- **Prompt Flow Tracing** - Visual trace of LLM calls, tool invocations
- **LangSmith** (LangChain) - Debug agent chains, view conversation replay

### Section 14.9: Common Multi-Agent Pitfalls

Avoid these anti-patterns:

1. ❌ **Unnecessary complexity** - Using multi-agent when single-agent + tools would suffice
2. ❌ **No specialization** - Agents that don't provide meaningful domain separation
3. ❌ **Ignoring latency** - Each handoff adds 1-3 seconds; 5 agents = 5-15s latency
4. ❌ **Shared mutable state** - Concurrent agents modifying same data without locks
5. ❌ **No fallback strategy** - If Agent 2 fails, entire workflow fails (no graceful degradation)
6. ❌ **Infinite loops** - Group chat without turn limits (agents talk forever)

### Section 14.10: References & Resources

- [AI agent orchestration patterns (Azure Architecture Center)](https://learn.microsoft.com/azure/architecture/ai-ml/guide/ai-agent-design-patterns)
- [Microsoft Agent Framework documentation](https://learn.microsoft.com/agent-framework/overview/agent-framework-overview)
- [Microsoft Agent Framework GitHub](https://github.com/microsoft/agent-framework)
- [Semantic Kernel agent orchestration](https://learn.microsoft.com/semantic-kernel/frameworks/agent/agent-orchestration/)
- [Multiple-agent workflow automation (Azure)](https://learn.microsoft.com/azure/architecture/ai-ml/idea/multiple-agent-workflow-automation)
- [Single vs multi-agent decision guide](https://learn.microsoft.com/azure/cloud-adoption-framework/ai-agents/single-agent-multiple-agents)

---

## Article XV: MLOps Lifecycle & Continuous Training

> **📋 Applies to**: AI/ML projects with custom models requiring retraining, monitoring, and lifecycle management
> **⏭️ Skip if**: Using only pre-built services (Azure Cognitive Services) or fine-tuned models without retraining
> **References**: [MLOps v2 Architecture (Microsoft)](https://learn.microsoft.com/azure/architecture/ai-ml/guide/machine-learning-operations-v2)

**MLOps** applies DevOps principles to machine learning: versioning models, automating training pipelines, continuous deployment, and monitoring for model drift. This article covers the end-to-end ML lifecycle from training to production to retraining.

### Section 15.1: MLOps Maturity Levels

Assess your current MLOps maturity and target level:

| Level                             | Characteristics                                                      | When to use                     |
| --------------------------------- | -------------------------------------------------------------------- | ------------------------------- |
| **Level 0: Manual**               | Jupyter notebooks, manual training, no versioning                    | POCs, research projects         |
| **Level 1: DevOps for ML**        | Automated training pipelines, model registry, CI/CD for code         | First production models         |
| **Level 2: Automated Retraining** | Scheduled retraining, automated deployment on approval               | Models require periodic updates |
| **Level 3: Full MLOps**           | Drift detection triggers retraining, A/B testing, canary deployments | Business-critical models        |

**Target**: Achieve Level 2-3 for production models.

### Section 15.2: ML Model Registry & Versioning

**Model Registry** - Centralized repository for trained models with versioning, metadata, and lineage tracking.

Select ONE:

- [ ] **Azure ML Model Registry** (recommended) - RBAC, tags, deployment history, audit logs
- [ ] **MLflow Model Registry** - Open-source, platform-agnostic
- [ ] **Git LFS (NOT recommended for production)** - Large binary files in Git (no metadata, no audit trail)

**Model Metadata to Track**:

| Metadata                | Example                          | Why track              |
| ----------------------- | -------------------------------- | ---------------------- |
| **Model version**       | `v1.2.3`                         | Rollback capability    |
| **Training dataset ID** | `dataset-2024-Q4`                | Reproducibility        |
| **Hyperparameters**     | `{"learning_rate": 0.001}`       | Experiment tracking    |
| **Evaluation metrics**  | `{"accuracy": 0.92, "f1": 0.89}` | Compare model versions |
| **Training date**       | `2024-12-15`                     | Audit compliance       |
| **Git commit SHA**      | `abc123`                         | Code-model linkage     |

**Example** (Azure ML Model Registry):

```python
from azure.ai.ml import MLClient
from azure.ai.ml.entities import Model

ml_client = MLClient(...)

# Register model
model = Model(
    path="./model/ files",
    name="fraud-detection-model",
    version="1.2.3",
    description="XGBoost fraud detection trained on Q4 2024 data",
    tags={"dataset": "fraud-2024-Q4", "accuracy": "0.92"}
)

ml_client.models.create_or_update(model)
```

### Section 15.3: Training Pipeline Automation

**ML Training Pipeline Components**:

1. **Data Ingestion** - Fetch training data from data lake/warehouse
2. **Data Validation** - Check schema, distributions, missing values
3. **Feature Engineering** - Transform raw data → features
4. **Model Training** - Train model on processed data
5. **Model Evaluation** - Validate on holdout set, compute metrics
6. **Model Registration** - Store in model registry (if metrics pass threshold)
7. **Model Deployment** - Deploy to staging/production (manual approval)

**Pipeline Orchestration Tools**:

- [ ] **Azure ML Pipelines** - YAML-defined pipelines, component reuse, parallel execution
- [ ] **Azure Data Factory + Azure ML** - Hybrid data + ML pipelines
- [ ] **Jupyter Notebooks + Papermill** - NOT recommended (manual, not reproducible)

**Example** (Azure ML Pipeline YAML):

```yaml
$schema: https://azuremlschemas.azureedge.net/latest/pipelineJob.schema.json
type: pipeline

inputs:
  training_data:
    type: uri_folder
    path: azureml://datastores/workspaceblobstore/paths/training-data/

jobs:
  data_prep:
    type: command
    component: azureml:data-prep-component:1
    inputs:
      raw_data: ${{parent.inputs.training_data}}
    outputs:
      prepared_data:
        type: uri_folder

  train_model:
    type: command
    component: azureml:xgboost-train:1
    inputs:
      training_data: ${{parent.jobs.data_prep.outputs.prepared_data}}
    outputs:
      model_output:
        type: mlflow_model

  evaluate_model:
    type: command
    component: azureml:model-evaluate:1
    inputs:
      model: ${{parent.jobs.train_model.outputs.model_output}}
      test_data: azureml://datastores/workspaceblobstore/paths/test-data/
```

### Section 15.4: CI/CD for ML Models

**CI Pipeline** (Triggered on code commit):

- [ ] **Lint training scripts** - Flake8, Black (Python), ESLint (JS)
- [ ] **Unit test feature engineering** - Test transforms in isolation
- [ ] **Run training on sample data** - Smoke test (fast, small dataset)
- [ ] **Validate model outputs** - Check model file format, required metadata

**CD Pipeline** (Triggered after model training):

- [ ] **Model evaluation gate** - Deploy ONLY if accuracy > baseline
- [ ] **Deploy to staging endpoint** - Test with synthetic traffic
- [ ] **Integration tests** - Validate inference latency, output format
- [ ] **Deploy to production** - Manual approval required
- [ ] **A/B testing** - Split traffic 90% old model / 10% new model
- [ ] **Monitor for 7 days** - If metrics stable, promote to 100%

**Example** (Azure DevOps Pipeline):

```yaml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - src/training/*

stages:
  - stage: CI
    jobs:
      - job: TrainModel
        steps:
          - task: AzureCLI@2
            inputs:
              azureSubscription: 'ml-service-connection'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                az ml job create --file training-pipeline.yml --resource-group ml-rg --workspace-name ml-workspace

  - stage: CD_Staging
    dependsOn: CI
    jobs:
      - deployment: DeployStaging
        environment: 'staging'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: AzureCLI@2
                  inputs:
                    inlineScript: |
                      az ml online-endpoint create --name fraud-staging --file endpoint-staging.yml
                      az ml online-deployment create --name blue --endpoint fraud-staging --file deployment.yml

  - stage: CD_Production
    dependsOn: CD_Staging
    jobs:
      - deployment: DeployProduction
        environment: 'production' # Manual approval gate configured in Azure DevOps
        strategy:
          runOnce:
            deploy:
              steps:
                - task: AzureCLI@2
                  inputs:
                    inlineScript: |
                      az ml online-deployment update --name green --endpoint fraud-prod --traffic 10
                      # Monitor for 7 days, then update traffic to 100%
```

### Section 15.5: Model Monitoring & Drift Detection

**Monitoring Metrics**:

| Metric Type     | Metric                     | Alert Threshold     | Tool                  |
| --------------- | -------------------------- | ------------------- | --------------------- |
| **Performance** | Latency p95                | > 500ms             | Azure Monitor         |
| **Performance** | Throughput (req/sec)       | < 100/sec           | Azure Monitor         |
| **Data Drift**  | Feature distribution shift | KL divergence > 0.1 | Azure ML Data Drift   |
| **Model Drift** | Accuracy degradation       | < 85% (was 92%)     | Custom metric         |
| **Cost**        | Inference cost per request | > $0.05             | Azure Cost Management |

**Drift Detection Strategies**:

- [ ] **Statistical tests** - Kolmogorov-Smirnov, Chi-square for feature distributions
- [ ] **Embedding drift** - Monitor embeddings of inputs (dimensionality reduction + clustering)
- [ ] **Performance monitoring** - Track accuracy/precision/recall in production (requires labels)
- [ ] **Business metric monitoring** - Track downstream business KPIs (conversion rate, revenue)

**Example** (Azure ML Data Drift):

```python
from azure.ai.ml import MLClient
from azure.ai.ml.entities import DataDriftMonitor

ml_client = MLClient(...)

# Create data drift monitor
monitor = DataDriftMonitor(
    name="fraud-data-drift",
    compute="cpu-cluster",
    monitoring_target=online_endpoint,
    baseline_data_version="training-data-v1",
    monitoring_signals={
        "feature_drift": {
            "type": "DataDrift",
            "features": ["transaction_amount", "merchant_category", "time_of_day"],
            "drift_threshold": 0.1
        }
    }
)

ml_client.schedules.create_or_update(monitor)
```

### Section 15.6: Automated Retraining Triggers

**Retraining Triggers** - When should model automatically retrain?

- [ ] **Scheduled** - Every 30/60/90 days (calendar-based)
- [ ] **Data drift detected** - Feature distributions shift beyond threshold
- [ ] **Model drift detected** - Performance degrades below SLA
- [ ] **New data volume** - 10,000+ new labeled examples available
- [ ] **Business event** - Major product change, new user segment

**Retraining Pipeline**:

1. Trigger detected (drift alert, schedule)
2. Automated training pipeline runs
3. New model registered in model registry
4. Evaluation stage compares new model vs. current production model
5. If new model wins (accuracy > current + 2%), deploy to staging
6. Automated tests pass → Deploy to production with traffic split (10%)
7. Monitor for 7 days → Promote to 100% if stable

**Example** (Event Grid trigger):

```python
from azure.eventgrid import EventGridPublisherClient
from azure.ai.ml import MLClient

# Data drift event triggers retraining
def on_drift_detected(event):
    ml_client = MLClient(...)

    # Submit training job
    job = ml_client.jobs.create_or_update(
        yaml_file="training-pipeline.yml"
    )

    print(f"Retraining triggered: {job.name}")
```

### Section 15.7: Model Deployment Strategies

Select ONE deployment pattern:

- [ ] **Blue-Green Deployment** - Two environments (blue = old, green = new), instant traffic switch
  - **Pro**: Zero downtime, instant rollback
  - **Con**: 2x infrastructure cost during transition

- [ ] **Canary Deployment** - Gradual traffic shift (1% → 10% → 50% → 100%)
  - **Pro**: Risk mitigation, early detection of issues
  - **Con**: Requires traffic splitting, monitoring

- [ ] **Rolling Update** - Replace instances gradually (Kubernetes rolling update)
  - **Pro**: No extra infrastructure cost
  - **Con**: Mixed versions during rollout

- [ ] **Shadow Deployment** - New model runs in parallel, predictions logged (not served to users)
  - **Pro**: Zero user risk, compare models in production
  - **Con**: Double inference cost

**Recommendation**: Canary deployment for business-critical models, rolling update for cost-sensitive models.

### Section 15.8: A/B Testing for ML Models

**A/B Testing** - Compare model versions by serving different models to different user segments.

**Implementation**:

- [ ] **Traffic split**: 90% model A (baseline) / 10% model B (new)
- [ ] **Business metrics**: Track conversion rate, revenue per user
- [ ] **Statistical significance**: Minimum 1,000 samples per variant
- [ ] **Duration**: Run for 7-14 days (avoid weekly seasonality bias)

**Success Criteria**:

- Model B has ≥2% relative improvement in business metric
- Model B latency ≤ Model A latency
- No increase in user complaints

**Example** (Azure ML Traffic Split):

```bash
# Deploy two models to same endpoint, split traffic
az ml online-deployment create --name model-a --endpoint fraud-prod --model fraud-model:1 --traffic 90
az ml online-deployment create --name model-b --endpoint fraud-prod --model fraud-model:2 --traffic 10

# After 7 days, promote model-b if successful
az ml online-deployment update --name model-b --endpoint fraud-prod --traffic 100
az ml online-deployment delete --name model-a --endpoint fraud-prod
```

### Section 15.9: Model Explainability in Production

**Why**: Regulatory compliance (GDPR Article 22), debugging, trust.

**Explainability Tools**:

- [ ] **SHAP (SHapley Additive exPlanations)** - Feature importance per prediction
- [ ] **LIME (Local Interpretable Model-agnostic Explanations)** - Local approximation
- [ ] **InterpretML (Microsoft)** - Glass-box models (Explainable Boosting Machines)

**Integration**:

- Generate explanations on-demand for high-stakes predictions (loan approval, fraud flagged)
- Store explanations in database for audit trail
- Surface explanations in user interface ("Your application was declined because: income too low")

**Example**:

```python
import shap

# Load production model
model = mlflow.pyfunc.load_model("models:/fraud-detection/production")

# Generate explanation for specific prediction
explainer = shap.TreeExplainer(model)
shap_values = explainer.shap_values(transaction_features)

# Store in database for audit
explanations_db.insert({
    "transaction_id": "txn-123",
    "prediction": "fraud",
    "top_features": [
        {"name": "transaction_amount", "impact": 0.45},
        {"name": "merchant_risk_score", "impact": 0.32}
    ]
})
```

### Section 15.10: MLOps Cost Optimization

**Cost Drivers**:

1. **Training compute** - GPU/CPU clusters for training pipelines
2. **Inference endpoints** - Always-on VMs for real-time predictions
3. **Storage** - Model artifacts, training data, logs

**Optimization Strategies**:

- [ ] **Use spot instances for training** - 60-80% discount for interruptible workloads
- [ ] **Batch inference instead of online endpoints** - Pay only for execution time
- [ ] **Auto-scale endpoints** - Scale to zero when no traffic
- [ ] **Model quantization** - Reduce model size (FP32 → INT8) for faster/cheaper inference
- [ ] **Serverless inference** - Azure ML serverless endpoints (pay-per-request)
- [ ] **Cache predictions** - Redis cache for repeated queries

**Cost Monitoring**:

- Track cost-per-inference (total cost / # predictions)
- Set budgets and alerts in Azure Cost Management
- Compare model versions by cost efficiency (accuracy / cost)

### Section 15.11: References & Resources

- [MLOps v2 Architecture (Azure Architecture Center)](https://learn.microsoft.com/azure/architecture/ai-ml/guide/machine-learning-operations-v2)
- [Azure Machine Learning Pipelines](https://learn.microsoft.com/azure/machine-learning/concept-ml-pipelines)
- [Model monitoring and data drift](https://learn.microsoft.com/azure/machine-learning/how-to-monitor-datasets)
- [Deploy models with managed online endpoints](https://learn.microsoft.com/azure/machine-learning/concept-endpoints-online)
- [A/B testing with traffic splitting](https://learn.microsoft.com/azure/machine-learning/how-to-deploy-model-custom-output)
- [Responsible AI Dashboard](https://learn.microsoft.com/azure/machine-learning/concept-responsible-ai-dashboard)

---

## Article XVI: Security Policies 🔄

> **📋 Applies to**: ALL project types

### Section 16.1: Network Security

| Component                | Configuration                     |
| ------------------------ | --------------------------------- |
| Virtual Network          | [ ] Azure VNet [ ] None           |
| Private Endpoints        | [ ] Enabled [ ] Disabled          |
| Web Application Firewall | [ ] Azure Front Door WAF [ ] None |

### Section 16.2: Data Protection

| Policy                | Value                                                 |
| --------------------- | ----------------------------------------------------- |
| Encryption at Rest    | [ ] Azure-managed keys [ ] Customer-managed keys      |
| Encryption in Transit | TLS 1.2+ (mandatory)                                  |
| PII Handling          | [ ] Anonymization [ ] Pseudonymization [ ] Encryption |

### Section 16.3: Compliance Requirements

| Standard | Required       |
| -------- | -------------- |
| GDPR     | [ ] Yes [ ] No |
| HIPAA    | [ ] Yes [ ] No |
| SOC 2    | [ ] Yes [ ] No |
| PCI-DSS  | [ ] Yes [ ] No |

---

## Article XIX: Governance 🔄

> **📋 Applies to**: ALL project types

### Section 19.1: Constitution Amendments

1. **Proposal**: Any team member may propose amendments
2. **Review**: Tech Lead + Architect review required
3. **Approval**: Majority approval from signatories
4. **Implementation**: Update constitution + notify AI agents
5. **Versioning**: Semantic versioning (MAJOR.MINOR.PATCH)

### Section 19.2: AI Agent Compliance ⭐

> **This section is especially critical for the AI scope.** All AI agents and models built within this project MUST comply with this governance framework.

All AI agents operating in this project MUST:

1. **Read** this constitution before any operation
2. **Validate** all decisions against constitution principles
3. **FAIL** operations that violate constitution
4. **Request** amendment for justified exceptions
5. **Log** all constitution checks for audit

---

## Proposed Additions — AI Gaps 🆕

> The original constitution has **minimal AI/ML-specific guidance** beyond agent compliance (§19.2).
> The following are recommended Microsoft/Azure technologies and governance practices.

### AI Platform & Infrastructure

- **Azure AI Foundry**: Unified platform for building, evaluating, and deploying AI models. Use as the central hub for model management, fine-tuning, and prompt flow orchestration.
- **Azure OpenAI Service**: Managed GPT-4o, GPT-4, GPT-3.5-Turbo, DALL-E, Whisper. Use for chat, completions, embeddings, and vision capabilities with enterprise SLA.
- **Azure AI Search**: Vector and hybrid search for RAG (Retrieval-Augmented Generation) patterns. Supports semantic ranking, integrated vectorization, and knowledge mining.
- **Azure Machine Learning**: For custom model training, MLOps pipelines, model registry, and managed endpoints.

### Responsible AI

- **Microsoft Responsible AI Toolkit**: Assess fairness, interpretability, error analysis, and causal inference for ML models.
- **Azure AI Content Safety**: Real-time content moderation for text and images. Mandatory for any user-facing generative AI feature.
- **Transparency Notes**: Document model capabilities, limitations, and intended use for every deployed AI feature.
- **Human-in-the-Loop**: Define escalation paths for AI decisions with material impact. AI should augment, not replace, human judgment for critical actions.

### Prompt Engineering & Governance

- **Prompt Governance**: Maintain a prompt registry with versioning, A/B testing, and rollback capabilities. Treat prompts as code (review, test, version).
- **Prompt Injection Protection**: Use Azure AI Content Safety + system prompt hardening + input/output validation to mitigate prompt injection attacks.
- **Grounding & Citations**: All RAG-based responses MUST include source citations. Implement grounding detection to measure hallucination rates.
- **Token & Cost Management**: Set per-deployment token quotas. Monitor token usage via Azure Monitor + Application Insights custom metrics.

### Model Lifecycle

- **Model Evaluation**: Use Azure AI Foundry evaluations (relevance, coherence, groundedness, fluency, similarity) before promoting any model or prompt to production.
- **A/B Testing & Experimentation**: Use feature flags (Azure App Configuration) to route traffic between model versions. Track business metrics per variant.
- **Model Monitoring**: Track drift, latency p50/p95/p99, error rates, safety incidents via Application Insights. Set alerts for quality degradation.
- **Model Deprecation**: Establish SLA for model version retirement (e.g., 90-day notice) aligned with Azure OpenAI model lifecycle policies.

### AI-Specific Security

- **Data Boundaries**: Ensure training/evaluation data stays within Azure data residency requirements. Use Azure Private Endpoints for all AI service communication.
- **PII in Prompts**: Implement PII detection and redaction (Azure AI Language PII entity recognition) before sending user data to AI models.
- **Audit Logging**: Log all AI interactions (prompt, completion, tokens, latency, safety flags) to Azure Monitor for compliance and debugging.

---

## Signatories

| Role         | Name   | Date   | Signature |
| ------------ | ------ | ------ | --------- |
| Project Lead | [NAME] | [DATE] |           |
| Tech Lead    | [NAME] | [DATE] |           |
| Architect    | [NAME] | [DATE] |           |

---

## Revision History

| Version | Date       | Author         | Changes                                                                                                                                                                                 |
| ------- | ---------- | -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 3.0.0   | 2026-02-27 | GitHub Copilot | Added Article XIV: Multi-Agent Architectures (orchestration patterns, Microsoft Agent Framework) + Article XV: MLOps Lifecycle (training pipelines, CI/CD, drift detection, retraining) |
| 2.2.0   | 2026-02-26 | GitHub Copilot | Added Article XIII: AI Architecture & Platform Strategy (396 lines) with Azure AI decision framework                                                                                    |
| 2.1.0   | [DATE]     | [AUTHOR]       | Added Project Scope (App/Infra/Full Stack), Landing Zone templates, Infrastructure testing                                                                                              |
| 2.0.0   | [DATE]     | [AUTHOR]       | Complete rewrite with C#/Node.js options                                                                                                                                                |
| 1.0.0   | [DATE]     | [AUTHOR]       | Initial constitution                                                                                                                                                                    |
