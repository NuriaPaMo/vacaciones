---
name: skill-ai-architecture-patterns
description: Choose AI architecture pattern (RAG, MLOps, Pre-built Services, Agents, Prompt Engineering, Fine-tuning) for Azure OpenAI, Cognitive Services, or custom ML models. Use when implementing AI features, deciding between RAG vs fine-tuning, designing multi-agent workflows, selecting embeddings strategy, or choosing Azure AI services. Critical for all AI projects - helps avoid costly architecture mistakes.
---

# AI Architecture Patterns

## When to Use This Skill

Use this skill when you need to make architecture decisions for AI-powered applications. This skill helps you choose the right pattern based on your requirements, because different AI scenarios require fundamentally different approaches:

- **Implementing RAG for knowledge retrieval from enterprise documents**, because you need real-time access to current information without retraining models
- **Choosing between fine-tuning and prompt engineering for custom behaviors**, because understanding the tradeoffs (cost, data requirements, control) guides your investment
- **Designing multi-agent orchestration for complex AI workflows**, because breaking down tasks into specialized agents improves reliability and maintainability
- **Selecting between Azure OpenAI and pre-built Cognitive Services**, because sometimes pre-trained models for vision/speech/language are more cost-effective than generative AI
- **Implementing MLOps for model training, deployment, and monitoring**, because production ML requires lifecycle management, versioning, and drift detection
- **Architecting vector search for semantic similarity and hybrid search**, because finding relevant information requires understanding embeddings, chunking, and indexing strategies
- **Ensuring responsible AI with content filtering and monitoring**, because AI systems need guardrails for safety, fairness, and compliance

---

## Decision Framework

```text
What's your AI architecture need?

├─ Need knowledge retrieval from documents/data?
│  └─ RAG (Azure OpenAI + AI Search)
│     - Real-time knowledge without retraining
│     - Embed documents, vector search for context
│     - Augment prompts with relevant information
│
├─ Need custom domain behavior/terminology?
│  └─ Fine-tuning GPT Models
│     - Requires training data (100+ examples)
│     - Adapts model to specific domain
│     - Higher cost but better accuracy
│
├─ Need behavior control without data?
│  └─ Prompt Engineering
│     - System messages for behavior
│     - Few-shot learning (provide examples)
│     - Chain-of-thought reasoning
│     - Zero training data required
│
├─ Need complex workflows with reasoning?
│  └─ Multi-Agent Orchestration
│     - Semantic Kernel (C#) or LangChain (Python)
│     - Agent chains with tool calling
│     - Planners for multi-step tasks
│
├─ Need standard AI tasks (vision, speech)?
│  └─ Pre-built Cognitive Services
│     - Computer Vision, Speech, Language
│     - No ML expertise required
│     - Lower cost than generative AI
│
└─ Need model lifecycle management?
   └─ MLOps with Azure ML
      - Training pipelines, versioning
      - A/B testing, monitoring drift
      - Responsible AI dashboard
```

---

## Scoring Model

**This is a conversation starter**, not a prescription. Use this to explore tradeoffs with your team:

| Factor                 | RAG                          | Fine-tuning                 | Prompt Engineering         | Multi-Agent                 | Pre-built Services       | MLOps                          |
| ---------------------- | ---------------------------- | --------------------------- | -------------------------- | --------------------------- | ------------------------ | ------------------------------ |
| **Complexity**         | Medium (vector search)       | High (training required)    | Low (just prompts)         | High (orchestration)        | Low (API calls)          | Very High (pipelines)          |
| **Cost**               | Medium (embeddings + search) | High (training + inference) | Low (inference only)       | Medium (multiple calls)     | Low (pre-trained)        | High (compute + storage)       |
| **Maintenance**        | Medium (index updates)       | Low (retrain periodically)  | Low (adjust prompts)       | Medium (agent coordination) | Very Low (managed)       | High (monitoring + retraining) |
| **Flexibility**        | High (any documents)         | Medium (domain-specific)    | Very High (adjust anytime) | Very High (composable)      | Low (fixed capabilities) | Very High (custom models)      |
| **Time to Production** | Fast (days)                  | Slow (weeks)                | Very Fast (hours)          | Medium (days)               | Very Fast (hours)        | Slow (months)                  |
| **Data Requirements**  | Documents (any size)         | 100+ examples               | 0-5 examples (few-shot)    | Task definitions            | None (pre-trained)       | 1000+ labeled examples         |
| **Control**            | Medium (search tuning)       | High (model behavior)       | Low (prompt limits)        | High (agent logic)          | Low (API capabilities)   | Very High (full control)       |

---

## AI Architecture Patterns

### RAG (Retrieval-Augmented Generation)

**What it is**: Combines Azure OpenAI with Azure AI Search to retrieve relevant context before generating responses.

**How it works**:

1. Embed documents using `text-embedding-ada-002` model
2. Store embeddings in Azure AI Search vector index
3. User query → embed query → vector search for similar documents
4. Augment prompt with retrieved context
5. GPT generates response grounded in your data

**When to use**: Enterprise knowledge bases, customer support bots, document Q&A, real-time information retrieval without retraining.

**Key considerations**: Chunking strategy (overlap, size), hybrid search (vector + keyword), semantic ranking, index refresh frequency.

### Fine-Tuning GPT Models

**What it is**: Train Azure OpenAI models (GPT-3.5/GPT-4) on your domain-specific data to adapt behavior and terminology.

**How it works**:

1. Prepare training data in JSONL format (prompt-completion pairs)
2. Upload to Azure OpenAI fine-tuning API
3. Train custom model (hyperparameters: epochs, learning rate)
4. Deploy custom model endpoint

**When to use**: Custom terminology (legal, medical), consistent tone/style, domain expertise, when prompting alone isn't sufficient.

**Key considerations**: Requires 100+ high-quality examples, training cost, model versioning, validation dataset to prevent overfitting.

### Prompt Engineering

**What it is**: Control AI behavior through carefully crafted prompts without training data.

**Techniques**:

- **System messages**: Define role, behavior, constraints
- **Few-shot learning**: Provide 2-5 examples in prompt
- **Chain-of-thought**: Ask model to reason step-by-step
- **Temperature control**: Adjust creativity (0.0 = deterministic, 1.0 = creative)

**When to use**: Rapid prototyping, behavior tweaks, zero training data, cost-sensitive scenarios.

**Key considerations**: Token limits (context window), prompt injection vulnerabilities, consistency across runs, version prompts in code.

### Multi-Agent Orchestration

**What it is**: Compose multiple AI agents with specialized tools to solve complex workflows.

**Frameworks**:

- **Semantic Kernel** (C#): Microsoft's orchestration framework, planners, memory, skills
- **LangChain** (Python): Agent toolkit, ReAct pattern, tool calling, chains

**How it works**:

1. Define tools/skills (search, calculator, database, APIs)
2. Agent receives task and decides which tools to use
3. Planner creates multi-step plan
4. Execute plan with intermediate reasoning
5. Return final result

**When to use**: Complex workflows requiring reasoning, multi-step processes, combining multiple data sources, autonomous task execution.

**Key considerations**: Tool definition quality, error handling (failed steps), cost (multiple LLM calls), observability (trace agent decisions).

### Pre-built Cognitive Services

**What it is**: Azure-managed APIs for common AI tasks without ML expertise.

**Services**:

- **Computer Vision**: Image analysis, OCR, object detection
- **Speech**: Speech-to-text, text-to-speech, translation
- **Language**: Sentiment analysis, entity recognition, translation
- **Document Intelligence**: Form recognition, invoice processing

**When to use**: Standard AI capabilities, no ML team, fast time-to-market, lower cost than generative AI.

**Key considerations**: Limited customization, API rate limits, data residency, combining with Azure OpenAI for hybrid scenarios.

### MLOps with Azure ML

**What it is**: End-to-end machine learning lifecycle management for custom models.

**Components**:

- **Training pipelines**: Data prep, model training, hyperparameter tuning
- **Model registry**: Versioning, lineage, deployment metadata
- **Deployment**: Real-time endpoints (ACI, AKS), batch scoring
- **Monitoring**: Data drift, model performance, responsible AI metrics

**When to use**: Custom ML models (not LLMs), production ML at scale, compliance requirements (audit trails), A/B testing, model monitoring.

**Key considerations**: Pipeline complexity, compute costs, retraining cadence, CI/CD integration, responsible AI governance.

---

## Vector Search and Embeddings

- **Embeddings**: Convert text to numerical vectors using `text-embedding-ada-002` (1536 dimensions)
- **Cosine similarity**: Measure semantic similarity between vectors (-1 to 1)
- **Chunking**: Split documents into smaller pieces (500-1000 tokens) with overlap (10-20%)
- **Hybrid search**: Combine vector search (semantic) with keyword search (exact match) for best results
- **Indexing**: Azure AI Search manages vector indexes with HNSW algorithm for fast approximate nearest neighbor search

---

## Responsible AI

- **Content filtering**: Azure OpenAI includes built-in filters for hate, violence, sexual content (low/medium/high thresholds)
- **PII detection**: Use Azure AI Language to detect and redact personally identifiable information
- **Red teaming**: Test AI systems for vulnerabilities, prompt injection, jailbreaks
- **Monitoring**: Track usage patterns, detect anomalies, log prompts and completions (privacy considerations)
- **Fairness**: Evaluate model outputs across demographic groups, mitigate bias
- **Transparency**: Document model capabilities, limitations, intended use cases

---

## Quick Reference

| Pattern                | Primary Use Case    | Azure Services              | Development Effort    |
| ---------------------- | ------------------- | --------------------------- | --------------------- |
| **RAG**                | Knowledge retrieval | Azure OpenAI + AI Search    | Medium (indexing)     |
| **Fine-tuning**        | Custom domain       | Azure OpenAI                | High (data prep)      |
| **Prompt Engineering** | Behavior control    | Azure OpenAI                | Low (prompt design)   |
| **Multi-Agent**        | Complex workflows   | Semantic Kernel / LangChain | High (orchestration)  |
| **Pre-built Services** | Standard AI         | Cognitive Services          | Low (API integration) |
| **MLOps**              | Custom ML           | Azure ML                    | Very High (pipelines) |

---

## Common Pitfalls

- **RAG without proper chunking**: Large chunks lose context, small chunks miss connections. Test 500-1000 token chunks with 10-20% overlap.
- **Fine-tuning with insufficient data**: Minimum 100 examples; quality > quantity. Validate with holdout set.
- **Prompt injection vulnerabilities**: User input can override system instructions. Sanitize inputs, use content filters.
- **Missing monitoring**: AI systems drift over time. Monitor costs, latency, accuracy, and user feedback. Set alerts.
- **Ignoring responsible AI**: Content safety, PII handling, bias detection are not optional. Build guardrails from day one.
- **Wrong pattern for the problem**: Don't use MLOps for simple classification. Don't use RAG if fine-tuning is better. Match complexity to need.

---

## Bundled Resources

For detailed code examples, see [code-examples.md](references/code-examples.md).
For Microsoft documentation, see [microsoft-learn.md](references/microsoft-learn.md).
