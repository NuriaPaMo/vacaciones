# TDD GREEN Phase Examples

## Backend Example (.NET)

### Minimal Implementation to Make Test Pass

```csharp
// File: src/TimeTracking.Domain/Entities/Account.cs
namespace TimeTracking.Domain.Entities;

public class Account
{
    public string Code { get; private set; }
    public string Name { get; private set; }
    
    private Account(string code, string name)
    {
        Code = code;
        Name = name;
    }
    
    public static Result<Account> Create(string code, string name)
    {
        // Simplest implementation - no validation yet
        // Just make the test pass!
        var account = new Account(code, name);
        return Result<Account>.Success(account);
    }
}

// Run: dotnet test
// Expected: All tests pass ✅
```

## Frontend Example (TypeScript)

### Minimal Implementation to Make Test Pass

```typescript
// File: src/stores/timeEntryStore.ts
import { defineStore } from 'pinia';

export interface TimeEntry {
  hours: number;
  account: string;
  date: string;
}

export const useTimeEntryStore = defineStore('timeEntry', {
  state: () => ({
    entries: [] as TimeEntry[]
  }),
  
  actions: {
    addEntry(entry: TimeEntry) {
      // Simplest thing that works
      this.entries.push(entry);
    }
  }
});

// Run: npm test
// Expected: All tests pass ✅
```

## Dealing with Complex Requirements

### Multiple Test Cases (Theory/InlineData)

```csharp
// Add more tests to drive more behavior
[Theory]
[InlineData("", "Name", false)]        // Empty code should fail
[InlineData("1234", "", false)]         // Empty name should fail  
[InlineData("1234", "Dev", true)]       // Valid should succeed

public void Create_WithVariousInputs_ReturnsExpectedResult(
    string code, 
    string name, 
    bool expectedSuccess)
{
    // Act
    var result = Account.Create(code, name);
    
    // Assert
    result.IsSuccess.Should().Be(expectedSuccess);
}

// These tests will FAIL initially - that's good!
```

### GREEN Phase: Add Just Enough Code

```csharp
public static Result<Account> Create(string code, string name)
{
    // Add validation incrementally to pass ALL tests
    if (string.IsNullOrWhiteSpace(code))
        return Result<Account>.Failure("Code is required");
        
    if (string.IsNullOrWhiteSpace(name))
        return Result<Account>.Failure("Name is required");
    
    var account = new Account(code, name);
    return Result<Account>.Success(account);
}

// Run: dotnet test
// Expected: All tests pass ✅
```

## GREEN Phase Workflow

1. **Write minimal code** - Simplest thing that makes test pass
2. **Run the test** - Should turn GREEN
3. **Run ALL tests** - Ensure nothing broke
4. **Commit** - `feat: implement Account creation`

## GREEN Phase Checklist

- [ ] Minimal code written (no over-engineering)
- [ ] New test PASSES
- [ ] ALL existing tests still pass
- [ ] No functionality added beyond test requirements
- [ ] Code committed to version control

## Common GREEN Phase Mistakes

### ❌ Over-Engineering

```typescript
// WRONG: Adding features not tested
addEntry(entry: TimeEntry) {
  // ❌ No test requires validation yet
  if (!this.validateEntry(entry)) return;
  
  // ❌ No test requires deduplication yet
  if (this.isDuplicate(entry)) return;
  
  // ✅ Only this is tested
  this.entries.push(entry);
}
```

### ✅ Keep It Simple

```typescript
// RIGHT: Just make the test pass
addEntry(entry: TimeEntry) {
  this.entries.push(entry);
}

// Add validation LATER when you have a test for it!
```

## Tips for GREEN Phase

- **Use hardcoded values** if needed - refactor later
- **Don't think about performance** yet - make it work first
- **Don't add error handling** unless tested
- **Keep cycles short** - 2-10 minutes max
- **Commit frequently** - small working increments
