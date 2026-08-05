# AI Architecture Patterns - Code Examples

## 1. RAG Implementation (C# with Azure OpenAI + AI Search)

```csharp
// Embed documents and create vector index
var openAIClient = new OpenAIClient(new Uri(endpoint), new AzureKeyCredential(apiKey));
var searchClient = new SearchIndexClient(new Uri(searchEndpoint), new AzureKeyCredential(searchKey));

// Create embeddings for documents
var documents = LoadDocuments();
foreach (var doc in documents)
{
    var embeddingResponse = await openAIClient.GetEmbeddingsAsync(
        new EmbeddingsOptions("text-embedding-ada-002", new[] { doc.Content }));
    doc.Embedding = embeddingResponse.Value.Data[0].Embedding.ToArray();
}

// Query with RAG
var queryEmbedding = await openAIClient.GetEmbeddingsAsync(
    new EmbeddingsOptions("text-embedding-ada-002", new[] { userQuery }));

var searchResults = await searchClient.SearchAsync<Document>(
    userQuery,
    new SearchOptions
    {
        VectorQueries = { new VectorQuery(queryEmbedding.Value.Data[0].Embedding) { KNearestNeighborsCount = 3 } }
    });

var context = string.Join("\n", searchResults.Value.GetResults().Select(r => r.Document.Content));
var prompt = $"Context: {context}\n\nQuestion: {userQuery}\nAnswer:";

var completion = await openAIClient.GetChatCompletionsAsync(
    new ChatCompletionsOptions("gpt-4", new[] { new ChatMessage(ChatRole.User, prompt) }));
```

## 2. RAG Implementation (Python with LangChain)

```python
from langchain.embeddings import AzureOpenAIEmbeddings
from langchain.vectorstores import AzureSearch
from langchain.chat_models import AzureChatOpenAI
from langchain.chains import RetrievalQA

# Initialize components
embeddings = AzureOpenAIEmbeddings(
    deployment="text-embedding-ada-002",
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT")
)

vector_store = AzureSearch(
    azure_search_endpoint=os.getenv("AZURE_SEARCH_ENDPOINT"),
    azure_search_key=os.getenv("AZURE_SEARCH_KEY"),
    index_name="documents",
    embedding_function=embeddings.embed_query
)

llm = AzureChatOpenAI(
    deployment_name="gpt-4",
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT")
)

# Create RAG chain
qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    chain_type="stuff",
    retriever=vector_store.as_retriever(search_kwargs={"k": 3})
)

# Query
answer = qa_chain.run("What is the company's vacation policy?")
```

## 3. Fine-Tuning GPT Model

```python
import openai
import json

# Prepare training data (JSONL format)
training_data = [
    {"messages": [
        {"role": "system", "content": "You are a medical assistant."},
        {"role": "user", "content": "What is hypertension?"},
        {"role": "assistant", "content": "Hypertension is high blood pressure..."}
    ]},
    # ... more examples (minimum 10 recommended)
]

with open("training_data.jsonl", "w") as f:
    for item in training_data:
        f.write(json.dumps(item) + "\n")

# Upload training file
client = openai.AzureOpenAI(azure_endpoint=endpoint, api_key=api_key, api_version="2024-02-01")

training_file = client.files.create(
    file=open("training_data.jsonl", "rb"),
    purpose="fine-tune"
)

# Create fine-tuning job
fine_tune_job = client.fine_tuning.jobs.create(
    training_file=training_file.id,
    model="gpt-35-turbo",
    hyperparameters={"n_epochs": 3}
)

# Monitor and deploy
print(f"Fine-tuning job ID: {fine_tune_job.id}")
# Once complete, deploy custom model to Azure OpenAI
```

## 4. Prompt Engineering Patterns

```csharp
// System message for behavior control
var systemMessage = new ChatMessage(ChatRole.System, @"
You are a helpful financial advisor. Follow these rules:
- Always ask clarifying questions before giving advice
- Never provide specific investment recommendations
- Focus on educational content and principles
- Be conservative and risk-aware in your guidance
");

// Few-shot learning (provide examples)
var fewShotPrompt = @"
Examples:
Q: Should I invest in crypto?
A: Before I can help, I need to understand your financial situation better. What's your risk tolerance and investment timeline?

Q: What's a good savings rate?
A: A common guideline is the 50/30/20 rule: 50% needs, 30% wants, 20% savings. However, this depends on your income, expenses, and goals.

Now answer this question:
Q: How much should I save for retirement?
A:";

// Chain-of-thought prompting
var chainOfThoughtPrompt = @"
Let's solve this step by step:
1. First, calculate the monthly expenses: $3000
2. Then, determine emergency fund target: 6 months × $3000 = $18,000
3. Current savings: $5,000
4. Amount to save: $18,000 - $5,000 = $13,000
5. Savings rate: $500/month
6. Time needed: $13,000 / $500 = 26 months

Therefore, you need to save for 26 months to reach your emergency fund goal.
";

// Temperature control for creativity vs consistency
var chatOptions = new ChatCompletionsOptions
{
    Temperature = 0.2f,  // Low = more consistent, factual
    // Temperature = 0.9f,  // High = more creative, varied
    MaxTokens = 500,
    TopP = 0.95f
};
```

## 5. Multi-Agent Orchestration (Semantic Kernel - C#)

```csharp
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Orchestration;

var kernel = Kernel.Builder
    .WithAzureChatCompletionService("gpt-4", endpoint, apiKey)
    .Build();

// Define skills (tools)
kernel.ImportSkill(new EmailSkill(), "Email");
kernel.ImportSkill(new CalendarSkill(), "Calendar");
kernel.ImportSkill(new SearchSkill(), "Search");

// Create planner for multi-step workflows
var planner = new SequentialPlanner(kernel);

var plan = await planner.CreatePlanAsync("Find recent emails about the sales meeting, check my calendar for availability next week, and draft a response proposing a time.");

// Execute plan (agent orchestration)
var result = await kernel.RunAsync(plan);

// Agent with memory
var memory = kernel.Memory;
await memory.SaveInformationAsync("meetings", "Sales meeting scheduled for June 15", "meeting_001");

var context = kernel.CreateNewContext();
context["input"] = "What meetings do I have coming up?";
var response = await kernel.RunAsync(context, kernel.Skills.GetFunction("Memory", "Recall"));
```

## 6. Multi-Agent Orchestration (LangChain - Python)

```python
from langchain.agents import initialize_agent, Tool, AgentType
from langchain.chat_models import AzureChatOpenAI
from langchain.chains import LLMMathChain
from langchain.utilities import SerpAPIWrapper

llm = AzureChatOpenAI(deployment_name="gpt-4", temperature=0)

# Define tools
search = SerpAPIWrapper()
llm_math = LLMMathChain.from_llm(llm)

tools = [
    Tool(
        name="Search",
        func=search.run,
        description="Useful for searching current information on the internet"
    ),
    Tool(
        name="Calculator",
        func=llm_math.run,
        description="Useful for mathematical calculations"
    )
]

# Initialize agent with ReAct pattern
agent = initialize_agent(
    tools,
    llm,
    agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
    verbose=True
)

# Execute complex workflow
result = agent.run(
    "What's the population of Tokyo? Calculate what 15% of that number is."
)

# Output shows reasoning steps:
# Thought: I need to search for Tokyo's population
# Action: Search[population of Tokyo]
# Observation: Tokyo has approximately 14 million people
# Thought: Now I need to calculate 15% of 14 million
# Action: Calculator[14000000 * 0.15]
# Observation: 2100000
# Final Answer: 15% of Tokyo's population (14 million) is 2.1 million people.
```

## 7. Pre-built Cognitive Services (Computer Vision + Speech)

```csharp
using Azure.AI.Vision.ImageAnalysis;
using Microsoft.CognitiveServices.Speech;

// Computer Vision - Image Analysis
var visionClient = new ImageAnalysisClient(
    new Uri(visionEndpoint),
    new AzureKeyCredential(visionKey));

var imageUrl = new Uri("https://example.com/image.jpg");
var result = await visionClient.AnalyzeAsync(
    imageUrl,
    VisualFeatures.Caption | VisualFeatures.Objects | VisualFeatures.Tags);

Console.WriteLine($"Caption: {result.Value.Caption.Text}");
foreach (var obj in result.Value.Objects)
{
    Console.WriteLine($"Object: {obj.Tags[0].Name} (confidence: {obj.Confidence:P})");
}

// Speech-to-Text
var speechConfig = SpeechConfig.FromSubscription(speechKey, speechRegion);
speechConfig.SpeechRecognitionLanguage = "en-US";

using var audioConfig = AudioConfig.FromDefaultMicrophone();
using var recognizer = new SpeechRecognizer(speechConfig, audioConfig);

var speechResult = await recognizer.RecognizeOnceAsync();
Console.WriteLine($"Transcription: {speechResult.Text}");

// Text-to-Speech
var ssml = @"
<speak version='1.0' xml:lang='en-US'>
    <voice name='en-US-JennyNeural'>
        <prosody rate='fast' pitch='high'>
            This is synthesized speech with emotion.
        </prosody>
    </voice>
</speak>";

using var synthesizer = new SpeechSynthesizer(speechConfig);
await synthesizer.SpeakSsmlAsync(ssml);
```

## 8. Azure ML MLOps Pipeline

```yaml
# Azure ML pipeline for training and deployment
$schema: https://azuremlschemas.azureedge.net/latest/pipelineJob.schema.json
type: pipeline
display_name: model_training_pipeline
experiment_name: customer_churn_prediction

inputs:
  training_data:
    type: uri_folder
    path: azureml://datastores/workspaceblobstore/paths/data/training

compute: azureml:cpu-cluster

jobs:
  prep_data:
    type: command
    component: azureml:data_prep:1.0
    inputs:
      raw_data: ${{parent.inputs.training_data}}
    outputs:
      processed_data:
        type: uri_folder

  train_model:
    type: command
    component: azureml:train_sklearn:1.0
    inputs:
      training_data: ${{parent.jobs.prep_data.outputs.processed_data}}
    outputs:
      model_output:
        type: mlflow_model

  evaluate_model:
    type: command
    component: azureml:evaluate:1.0
    inputs:
      model: ${{parent.jobs.train_model.outputs.model_output}}
      test_data: ${{parent.jobs.prep_data.outputs.processed_data}}
    outputs:
      evaluation_results:
        type: uri_file

  register_model:
    type: command
    inputs:
      model: ${{parent.jobs.train_model.outputs.model_output}}
      evaluation: ${{parent.jobs.evaluate_model.outputs.evaluation_results}}
    command: |
      python register_model.py \
        --model-path ${{inputs.model}} \
        --metrics-path ${{inputs.evaluation}}
```

```python
# Deploy registered model to Azure Container Instance
from azure.ai.ml import MLClient
from azure.ai.ml.entities import ManagedOnlineEndpoint, ManagedOnlineDeployment, Model

ml_client = MLClient.from_config()

# Create endpoint
endpoint = ManagedOnlineEndpoint(
    name="churn-prediction-endpoint",
    description="Customer churn prediction model",
    auth_mode="key"
)
ml_client.online_endpoints.begin_create_or_update(endpoint).result()

# Deploy model
model = ml_client.models.get(name="churn_model", version="1")

deployment = ManagedOnlineDeployment(
    name="production",
    endpoint_name="churn-prediction-endpoint",
    model=model,
    instance_type="Standard_DS2_v2",
    instance_count=2,
    environment_variables={
        "AZURE_OPENAI_ENDPOINT": os.getenv("OPENAI_ENDPOINT")
    }
)

ml_client.online_deployments.begin_create_or_update(deployment).result()

# A/B testing with traffic split
endpoint.traffic = {"production": 80, "canary": 20}
ml_client.online_endpoints.begin_create_or_update(endpoint).result()
```
