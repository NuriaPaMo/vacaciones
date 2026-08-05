# TDD RED Phase Examples

## Backend Example (.NET/xUnit)

### Test Written FIRST (RED Phase)

```csharp
// File: tests/TimeTracking.UnitTests/Domain/Entities/AccountTests.cs
using FluentAssertions;
using TimeTracking.Domain.Entities;
using Xunit;

namespace TimeTracking.UnitTests.Domain.Entities;

public class AccountTests
{
    [Fact]
    public void Create_WithValidData_ShouldReturnSuccess()
    {
        // Arrange
        var code = "1234";
        var name = "Development";
        
        // Act - This method doesn't exist yet!
        var result = Account.Create(code, name);
        
        // Assert - This will fail
        result.IsSuccess.Should().BeTrue();
        result.Value.Code.Should().Be(code);
        result.Value.Name.Should().Be(name);
    }
}

// Run: dotnet test
// Expected: Compilation error - Account.Create doesn't exist ✅
// This is GOOD! The test fails for the right reason.
```

## Frontend Example (TypeScript/Vitest)

### Test Written FIRST (RED Phase)

```typescript
// File: src/stores/__tests__/timeEntryStore.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { useTimeEntryStore } from '../timeEntryStore';

describe('TimeEntryStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it('should add time entry to store', () => {
    // Arrange
    const store = useTimeEntryStore();
    const entry = { hours: 2, account: 'DEV-001', date: '2026-02-17' };
    
    // Act - This method doesn't exist yet!
    store.addEntry(entry);
    
    // Assert - This will fail
    expect(store.entries).toHaveLength(1);
    expect(store.entries[0]).toEqual(entry);
  });
});

// Run: npm test
// Expected: TypeError - addEntry is not a function ✅
// This is GOOD! The test fails because we haven't implemented it yet.
```

## RED Phase Workflow

1. **Write the test** - Describe WHAT should happen
2. **Run the test** - Verify it FAILS
3. **Check failure reason** - Must fail for the RIGHT reason
   - ✅ Method doesn't exist
   - ✅ Wrong return value
   - ❌ Syntax error (fix your test!)
   - ❌ Import error (fix your test!)
4. **Commit** - `test: add failing test for Account creation`

## RED Phase Checklist

- [ ] Test follows AAA pattern (Arrange, Act, Assert)
- [ ] Test name clearly describes expected behavior
- [ ] Test runs and FAILS
- [ ] Failure message is clear and expected
- [ ] Only ONE new test added
- [ ] Test committed to version control
