# Saga & Workflow Orchestration - Code Examples

## 1. Durable Functions Function Chaining (Sequential Saga)

```csharp
// OrderSaga.cs - Sequential order processing with function chaining
[FunctionName("OrderSaga_HttpStart")]
public static async Task<HttpResponseMessage> HttpStart(
    [HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequestMessage req,
    [DurableClient] IDurableOrchestrationClient starter)
{
    var order = await req.Content.ReadAsAsync<Order>();
    string instanceId = await starter.StartNewAsync("OrderSaga", order);
    return starter.CreateCheckStatusResponse(req, instanceId);
}

[FunctionName("OrderSaga")]
public static async Task<OrderResult> RunOrchestrator(
    [OrchestrationTrigger] IDurableOrchestrationContext context)
{
    var order = context.GetInput<Order>();

    // Sequential steps with automatic checkpointing
    var inventory = await context.CallActivityAsync<bool>("ReserveInventory", order);
    var payment = await context.CallActivityAsync<string>("ChargePayment", order);
    var shipment = await context.CallActivityAsync<string>("ShipOrder", order);

    return new OrderResult
    {
        OrderId = order.Id,
        InventoryReserved = inventory,
        PaymentId = payment,
        ShipmentId = shipment
    };
}

[FunctionName("ReserveInventory")]
public static async Task<bool> ReserveInventory([ActivityTrigger] Order order, ILogger log)
{
    log.LogInformation($"Reserving inventory for order {order.Id}");
    await CallInventoryServiceAsync(order);
    return true;
}
```

**Pattern**: Function chaining executes activities sequentially with automatic state persistence via checkpointing. Durable Functions replays orchestrator from history after failures.

---

## 2. Durable Functions Fan-Out/Fan-In (Parallel Activities)

```csharp
// ParallelSaga.cs - Parallel processing with fan-out/fan-in pattern
[FunctionName("ParallelOrderSaga")]
public static async Task<OrderResult> RunOrchestrator(
    [OrchestrationTrigger] IDurableOrchestrationContext context)
{
    var order = context.GetInput<Order>();

    // Fan-out: Start 3 activities in parallel
    var tasks = new List<Task>
    {
        context.CallActivityAsync("ValidateInventory", order),
        context.CallActivityAsync("ValidateCredit", order),
        context.CallActivityAsync("ValidateShippingAddress", order)
    };

    // Fan-in: Wait for all validations to complete
    await Task.WhenAll(tasks);

    // Continue with sequential fulfillment
    var payment = await context.CallActivityAsync<string>("ProcessPayment", order);
    var shipment = await context.CallActivityAsync<string>("CreateShipment", order);

    return new OrderResult { PaymentId = payment, ShipmentId = shipment };
}
```

**Pattern**: Fan-out/fan-in runs multiple activities concurrently, waits for all to complete, then continues. Reduces total execution time for independent operations.

---

## 3. Durable Functions Saga with Compensation (Try/Catch Rollback)

```csharp
// CompensatingSaga.cs - Saga with compensation logic for rollback
[FunctionName("CompensatingSaga")]
public static async Task<OrderResult> RunOrchestrator(
    [OrchestrationTrigger] IDurableOrchestrationContext context)
{
    var order = context.GetInput<Order>();
    bool inventoryReserved = false;
    string paymentId = null;

    try
    {
        // Step 1: Reserve inventory
        inventoryReserved = await context.CallActivityAsync<bool>("ReserveInventory", order);

        // Step 2: Charge payment
        paymentId = await context.CallActivityAsync<string>("ChargePayment", order);

        // Step 3: Ship order
        var shipmentId = await context.CallActivityAsync<string>("ShipOrder", order);

        return new OrderResult { Success = true, ShipmentId = shipmentId };
    }
    catch (Exception ex)
    {
        // Compensation: Undo completed steps in reverse order
        if (paymentId != null)
            await context.CallActivityAsync("RefundPayment", paymentId);

        if (inventoryReserved)
            await context.CallActivityAsync("CancelInventoryReservation", order.Id);

        return new OrderResult { Success = false, Error = ex.Message };
    }
}

[FunctionName("RefundPayment")]
public static async Task RefundPayment([ActivityTrigger] string paymentId, ILogger log)
{
    log.LogInformation($"Refunding payment {paymentId}");
    await CallPaymentServiceAsync("refund", paymentId);
}

[FunctionName("CancelInventoryReservation")]
public static async Task CancelInventoryReservation([ActivityTrigger] string orderId, ILogger log)
{
    log.LogInformation($"Cancelling inventory reservation for order {orderId}");
    await CallInventoryServiceAsync("cancel", orderId);
}
```

**Pattern**: Try/catch with compensating activities implements saga rollback. Each step tracks state; on failure, compensations execute in reverse order.

---

## 4. Dapr Workflow Order Saga (Reserve, Charge, Ship with Compensation)

```python
# order_saga.py - Dapr Workflow saga with activities and compensation
from dapr.ext.workflow import WorkflowRuntime, DaprWorkflowContext, WorkflowActivityContext
from datetime import timedelta

def order_saga_workflow(ctx: DaprWorkflowContext, order: dict):
    """Orchestration-based saga with Dapr Workflow"""

    # Activity 1: Reserve inventory with timeout and retry
    inventory_result = yield ctx.call_activity(
        reserve_inventory,
        input=order,
        retry_policy={
            'max_attempts': 3,
            'first_retry_interval': timedelta(seconds=5),
            'backoff_coefficient': 2.0
        }
    )

    if not inventory_result['success']:
        return {'success': False, 'reason': 'Inventory reservation failed'}

    # Activity 2: Charge payment
    try:
        payment_result = yield ctx.call_activity(charge_payment, input=order)

        # Activity 3: Ship order
        shipment_result = yield ctx.call_activity(ship_order, input=order)

        return {
            'success': True,
            'order_id': order['id'],
            'shipment_id': shipment_result['shipment_id']
        }

    except Exception as e:
        # Compensating activities on failure
        yield ctx.call_activity(
            cancel_inventory_reservation,
            input={'reservation_id': inventory_result['reservation_id']}
        )

        if 'payment_id' in locals():
            yield ctx.call_activity(
                refund_payment,
                input={'payment_id': payment_result['payment_id']}
            )

        return {'success': False, 'reason': str(e)}

def reserve_inventory(ctx: WorkflowActivityContext, order: dict):
    """Activity: Reserve inventory"""
    print(f"Reserving inventory for order {order['id']}")
    # Call inventory service
    reservation_id = call_inventory_service(order)
    return {'success': True, 'reservation_id': reservation_id}

def charge_payment(ctx: WorkflowActivityContext, order: dict):
    """Activity: Charge payment"""
    print(f"Charging payment for order {order['id']}")
    payment_id = call_payment_service(order)
    return {'payment_id': payment_id}

def cancel_inventory_reservation(ctx: WorkflowActivityContext, data: dict):
    """Compensating activity: Cancel reservation"""
    print(f"Cancelling reservation {data['reservation_id']}")
    call_inventory_service_cancel(data['reservation_id'])

# Register workflow and activities
runtime = WorkflowRuntime()
runtime.register_workflow(order_saga_workflow)
runtime.register_activity(reserve_inventory)
runtime.register_activity(charge_payment)
runtime.register_activity(cancel_inventory_reservation)
runtime.start()
```

**Pattern**: Dapr Workflow provides saga orchestration with activity definitions, retry policies, and compensating activities. Workflow state persists in configured state store (Redis, Cosmos DB, SQL Server).

---

## 5. Dapr Workflow Sub-Workflows (Order Workflow Calls Payment Sub-Workflow)

```python
# sub_workflows.py - Modular saga with sub-workflows
from dapr.ext.workflow import DaprWorkflowContext

def order_workflow(ctx: DaprWorkflowContext, order: dict):
    """Main workflow orchestrates sub-workflows"""

    # Sub-workflow 1: Validate order
    validation_result = yield ctx.call_child_workflow(
        validate_order_workflow,
        input=order
    )

    if not validation_result['valid']:
        return {'success': False, 'reason': validation_result['reason']}

    # Sub-workflow 2: Process payment (complex multi-step)
    payment_result = yield ctx.call_child_workflow(
        payment_workflow,
        input=order
    )

    # Sub-workflow 3: Fulfillment
    fulfillment_result = yield ctx.call_child_workflow(
        fulfillment_workflow,
        input={'order': order, 'payment': payment_result}
    )

    return {
        'success': True,
        'order_id': order['id'],
        'payment_id': payment_result['payment_id'],
        'shipment_id': fulfillment_result['shipment_id']
    }

def payment_workflow(ctx: DaprWorkflowContext, order: dict):
    """Sub-workflow: Multi-step payment processing"""

    # Authorize
    auth_result = yield ctx.call_activity(authorize_payment, input=order)

    # Apply discounts
    discount_result = yield ctx.call_activity(calculate_discounts, input=order)

    # Capture payment
    capture_result = yield ctx.call_activity(
        capture_payment,
        input={'auth_id': auth_result['auth_id'], 'amount': discount_result['final_amount']}
    )

    return {'payment_id': capture_result['payment_id'], 'amount': discount_result['final_amount']}

def fulfillment_workflow(ctx: DaprWorkflowContext, data: dict):
    """Sub-workflow: Order fulfillment"""

    order = data['order']
    payment = data['payment']

    # Reserve inventory
    yield ctx.call_activity(reserve_inventory, input=order)

    # Create shipment
    shipment_result = yield ctx.call_activity(create_shipment, input=order)

    return {'shipment_id': shipment_result['shipment_id']}
```

**Pattern**: Sub-workflows provide modularity and reusability. Main workflow orchestrates child workflows, each managing its own scope. Enables complex saga decomposition.

---

## 6. Logic Apps Stateful Workflow (Approval with Timeout)

```json
{
  "definition": {
    "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
    "actions": {
      "Check_Order_Amount": {
        "type": "If",
        "expression": {
          "and": [
            {
              "greater": ["@triggerBody()?['amount']", 1000]
            }
          ]
        },
        "actions": {
          "Send_Approval_Email": {
            "type": "ApiConnection",
            "inputs": {
              "host": {
                "connection": {
                  "name": "@parameters('$connections')['office365']['connectionId']"
                }
              },
              "method": "post",
              "path": "/v2/Mail",
              "body": {
                "To": "manager@company.com",
                "Subject": "High-value order approval required",
                "Body": "Order @{triggerBody()?['orderId']} requires approval. Amount: $@{triggerBody()?['amount']}"
              }
            }
          },
          "Wait_For_Approval": {
            "type": "ApiConnection",
            "inputs": {
              "host": {
                "connection": {
                  "name": "@parameters('$connections')['office365']['connectionId']"
                }
              },
              "method": "post",
              "path": "/approvalmail/$subscriptions",
              "queries": {
                "Message": "Approve order @{triggerBody()?['orderId']}?",
                "NotificationUrl": "@{listCallbackUrl()}",
                "Timeout": "P7D"
              }
            },
            "runAfter": {
              "Send_Approval_Email": ["Succeeded"]
            }
          },
          "Approval_Decision": {
            "type": "If",
            "expression": {
              "and": [
                {
                  "equals": ["@body('Wait_For_Approval')?['SelectedOption']", "Approve"]
                }
              ]
            },
            "actions": {
              "Process_High_Value_Order": {
                "type": "Http",
                "inputs": {
                  "method": "POST",
                  "uri": "https://api.company.com/orders/process",
                  "body": "@triggerBody()"
                }
              }
            },
            "else": {
              "actions": {
                "Reject_Order": {
                  "type": "Http",
                  "inputs": {
                    "method": "POST",
                    "uri": "https://api.company.com/orders/reject",
                    "body": {
                      "orderId": "@triggerBody()?['orderId']",
                      "reason": "Manager rejected"
                    }
                  }
                }
              }
            },
            "runAfter": {
              "Wait_For_Approval": ["Succeeded"]
            }
          }
        },
        "else": {
          "actions": {
            "Process_Standard_Order": {
              "type": "Http",
              "inputs": {
                "method": "POST",
                "uri": "https://api.company.com/orders/process",
                "body": "@triggerBody()"
              }
            }
          }
        }
      }
    },
    "triggers": {
      "manual": {
        "type": "Request",
        "kind": "Http",
        "inputs": {
          "schema": {
            "type": "object",
            "properties": {
              "orderId": { "type": "string" },
              "amount": { "type": "number" }
            }
          }
        }
      }
    }
  }
}
```

**Pattern**: Logic Apps provides visual workflow designer with built-in connectors (Office 365, SQL, Salesforce). Stateful workflows persist state across long-running executions (days/weeks). Approval actions wait for human response with configurable timeout (P7D = 7 days).

---

## 7. Service Bus Choreography (Event-Driven Saga with Correlation ID)

```csharp
// ServiceBusChoreography.cs - Event-driven saga without central coordinator
public class OrderService
{
    private readonly ServiceBusSender _sender;

    public async Task CreateOrder(Order order)
    {
        // Generate correlation ID for saga tracking
        var correlationId = Guid.NewGuid().ToString();

        // Publish OrderPlaced event
        var message = new ServiceBusMessage(JsonSerializer.Serialize(order))
        {
            CorrelationId = correlationId,
            Subject = "order.placed"
        };

        await _sender.SendMessageAsync(message);
    }
}

public class InventoryService
{
    private readonly ServiceBusReceiver _receiver;
    private readonly ServiceBusSender _sender;

    public async Task ProcessMessages()
    {
        await _receiver.SubscribeAsync("order.placed", async (message) =>
        {
            var order = JsonSerializer.Deserialize<Order>(message.Body);

            try
            {
                // Reserve inventory
                await ReserveInventoryAsync(order);

                // Publish InventoryReserved event
                var successMessage = new ServiceBusMessage(JsonSerializer.Serialize(order))
                {
                    CorrelationId = message.CorrelationId,
                    Subject = "inventory.reserved"
                };

                await _sender.SendMessageAsync(successMessage);
            }
            catch (Exception ex)
            {
                // Publish InventoryReservationFailed event
                var failureMessage = new ServiceBusMessage(JsonSerializer.Serialize(new { order.Id, Error = ex.Message }))
                {
                    CorrelationId = message.CorrelationId,
                    Subject = "inventory.reservation.failed"
                };

                await _sender.SendMessageAsync(failureMessage);
            }
        });
    }
}

public class PaymentService
{
    private readonly ServiceBusReceiver _receiver;
    private readonly ServiceBusSender _sender;

    public async Task ProcessMessages()
    {
        // Listen for inventory.reserved event
        await _receiver.SubscribeAsync("inventory.reserved", async (message) =>
        {
            var order = JsonSerializer.Deserialize<Order>(message.Body);

            try
            {
                var paymentId = await ChargePaymentAsync(order);

                var successMessage = new ServiceBusMessage(JsonSerializer.Serialize(new { order.Id, PaymentId = paymentId }))
                {
                    CorrelationId = message.CorrelationId,
                    Subject = "payment.completed"
                };

                await _sender.SendMessageAsync(successMessage);
            }
            catch (Exception ex)
            {
                // Publish compensation event
                var compensateMessage = new ServiceBusMessage(JsonSerializer.Serialize(new { order.Id }))
                {
                    CorrelationId = message.CorrelationId,
                    Subject = "inventory.cancel.requested"
                };

                await _sender.SendMessageAsync(compensateMessage);
            }
        });

        // Listen for compensation request
        await _receiver.SubscribeAsync("inventory.cancel.requested", async (message) =>
        {
            var data = JsonSerializer.Deserialize<dynamic>(message.Body);
            await CancelInventoryReservationAsync(data.Id);
        });
    }
}
```

**Pattern**: Choreography-based saga uses event-driven communication without central coordinator. Each service listens for events, performs actions, and publishes new events. Correlation ID tracks saga across services. More resilient but harder to monitor than orchestration.

---

## 8. Saga State Machine Pattern (Explicit States and Transitions)

```csharp
// SagaStateMachine.cs - Explicit state machine for saga tracking
public enum OrderSagaState
{
    Pending,
    InventoryReserved,
    PaymentProcessed,
    Shipped,
    Failed,
    Compensating,
    Compensated
}

public class OrderSaga
{
    public string OrderId { get; set; }
    public OrderSagaState State { get; set; }
    public Dictionary<string, object> Context { get; set; } = new();
    public List<string> CompletedSteps { get; set; } = new();
    public string FailureReason { get; set; }
}

public class OrderSagaOrchestrator
{
    private readonly ISagaRepository _repository;

    public async Task<OrderSaga> ExecuteSaga(Order order)
    {
        var saga = new OrderSaga
        {
            OrderId = order.Id,
            State = OrderSagaState.Pending
        };

        await _repository.SaveAsync(saga);

        // Step 1: Reserve inventory
        saga = await TransitionToInventoryReservedAsync(saga, order);

        if (saga.State == OrderSagaState.Failed)
            return await CompensateAsync(saga);

        // Step 2: Process payment
        saga = await TransitionToPaymentProcessedAsync(saga, order);

        if (saga.State == OrderSagaState.Failed)
            return await CompensateAsync(saga);

        // Step 3: Ship order
        saga = await TransitionToShippedAsync(saga, order);

        return saga;
    }

    private async Task<OrderSaga> TransitionToInventoryReservedAsync(OrderSaga saga, Order order)
    {
        try
        {
            var reservationId = await CallInventoryServiceAsync(order);

            saga.State = OrderSagaState.InventoryReserved;
            saga.CompletedSteps.Add("inventory_reserved");
            saga.Context["reservation_id"] = reservationId;

            await _repository.SaveAsync(saga);
            return saga;
        }
        catch (Exception ex)
        {
            saga.State = OrderSagaState.Failed;
            saga.FailureReason = $"Inventory reservation failed: {ex.Message}";
            await _repository.SaveAsync(saga);
            return saga;
        }
    }

    private async Task<OrderSaga> TransitionToPaymentProcessedAsync(OrderSaga saga, Order order)
    {
        try
        {
            var paymentId = await CallPaymentServiceAsync(order);

            saga.State = OrderSagaState.PaymentProcessed;
            saga.CompletedSteps.Add("payment_processed");
            saga.Context["payment_id"] = paymentId;

            await _repository.SaveAsync(saga);
            return saga;
        }
        catch (Exception ex)
        {
            saga.State = OrderSagaState.Failed;
            saga.FailureReason = $"Payment processing failed: {ex.Message}";
            await _repository.SaveAsync(saga);
            return saga;
        }
    }

    private async Task<OrderSaga> CompensateAsync(OrderSaga saga)
    {
        saga.State = OrderSagaState.Compensating;
        await _repository.SaveAsync(saga);

        // Compensate in reverse order
        if (saga.CompletedSteps.Contains("payment_processed"))
        {
            var paymentId = saga.Context["payment_id"] as string;
            await RefundPaymentAsync(paymentId);
        }

        if (saga.CompletedSteps.Contains("inventory_reserved"))
        {
            var reservationId = saga.Context["reservation_id"] as string;
            await CancelInventoryReservationAsync(reservationId);
        }

        saga.State = OrderSagaState.Compensated;
        await _repository.SaveAsync(saga);

        return saga;
    }
}
```

**Pattern**: State machine tracks saga with explicit states and transitions. Saga state persists to database for monitoring and recovery. Compensations execute in reverse order based on completed steps. Enables saga recovery after crashes and provides clear audit trail.

---

## Comparison Table: Orchestration vs Choreography

| Aspect               | Orchestration (Durable Functions, Dapr, Logic Apps) | Choreography (Service Bus Events)            |
| -------------------- | --------------------------------------------------- | -------------------------------------------- |
| **Coordination**     | Central orchestrator coordinates all steps          | No central coordinator, event-driven         |
| **Complexity**       | Simple to understand (sequential logic)             | Complex to understand (distributed events)   |
| **Monitoring**       | Easy - single orchestrator tracks progress          | Hard - distributed across services           |
| **Coupling**         | Orchestrator knows all services (higher coupling)   | Services only know events (loose coupling)   |
| **Failure Handling** | Orchestrator handles compensation logic             | Each service handles its own compensation    |
| **Debugging**        | Easier - single entry point                         | Harder - trace events across services        |
| **Scalability**      | Orchestrator can be bottleneck                      | More scalable (no central coordinator)       |
| **Best For**         | Workflows with clear sequence, human-in-loop        | Event-driven systems, microservices autonomy |
