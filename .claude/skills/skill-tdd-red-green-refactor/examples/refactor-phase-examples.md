# TDD REFACTOR Phase Examples

## Backend Example (.NET) - Before/After

### BEFORE Refactor (Works but has issues)

```csharp
public static Result<Account> Create(string code, string name)
{
    // Issues:
    // - Long method
    // - Multiple responsibilities
    // - Hard to test individual validations
    // - Regex inline (magic string)
    
    if (string.IsNullOrWhiteSpace(code))
        return Result<Account>.Failure("Code is required");
        
    if (string.IsNullOrWhiteSpace(name))
        return Result<Account>.Failure("Name is required");
        
    if (code.Length > 10)
        return Result<Account>.Failure("Code too long");
        
    if (!Regex.IsMatch(code, "^[A-Z0-9-]+$"))
        return Result<Account>.Failure("Invalid code format");
    
    var account = new Account(code, name);
    return Result<Account>.Success(account);
}
```

### AFTER Refactor (Cleaner, more maintainable)

```csharp
public static Result<Account> Create(string code, string name)
{
    var validation = ValidateInput(code, name);
    if (validation.IsFailure)
        return validation;
    
    var account = new Account(code.ToUpperInvariant(), name.Trim());
    return Result<Account>.Success(account);
}

private static Result<Account> ValidateInput(string code, string name)
{
    var codeValidation = AccountCode.Validate(code);
    if (codeValidation.IsFailure)
        return Result<Account>.Failure(codeValidation.Error);
    
    var nameValidation = AccountName.Validate(name);
    if (nameValidation.IsFailure)
        return Result<Account>.Failure(nameValidation.Error);
    
    return Result<Account>.Success(null);
}

// Even better: Extract to Value Objects
public class AccountCode : ValueObject
{
    private const int MaxLength = 10;
    private const string ValidPattern = "^[A-Z0-9-]+$";
    
    public string Value { get; }
    
    private AccountCode(string value) => Value = value;
    
    public static Result<AccountCode> Create(string code)
    {
        if (string.IsNullOrWhiteSpace(code))
            return Result<AccountCode>.Failure("Code is required");
            
        if (code.Length > MaxLength)
            return Result<AccountCode>.Failure($"Code cannot exceed {MaxLength} characters");
            
        if (!Regex.IsMatch(code, ValidPattern))
            return Result<AccountCode>.Failure("Code must contain only uppercase letters, numbers, and hyphens");
        
        return Result<AccountCode>.Success(new AccountCode(code.ToUpperInvariant()));
    }
}
```

## Frontend Example (TypeScript) - Before/After

### BEFORE Refactor

```typescript
export const useTimeEntryStore = defineStore('timeEntry', {
  state: () => ({
    entries: [] as TimeEntry[]
  }),
  
  actions: {
    addEntry(entry: TimeEntry) {
      // Issues:
      // - Validation mixed with logic
      // - Throw errors (not composable)
      // - Magic numbers
      // - No normalization
      
      if (!entry.hours || entry.hours <= 0) {
        throw new Error('Invalid hours');
      }
      
      if (!entry.account) {
        throw new Error('Invalid account');
      }
      
      if (entry.hours > 24) {
        throw new Error('Hours cannot exceed 24');
      }
      
      this.entries.push(entry);
    }
  }
});
```

### AFTER Refactor (Extracted validation, better error handling)

```typescript
export const useTimeEntryStore = defineStore('timeEntry', {
  state: () => ({
    entries: [] as TimeEntry[]
  }),
  
  actions: {
    addEntry(entry: TimeEntry) {
      const validation = validateTimeEntry(entry);
      if (!validation.isValid) {
        throw new ValidationError(validation.errors);
      }
      
      this.entries.push(normalizeEntry(entry));
    }
  }
});

// Extracted validation (reusable and testable)
function validateTimeEntry(entry: TimeEntry): ValidationResult {
  const errors: string[] = [];
  
  if (!entry.hours || entry.hours <= 0) {
    errors.push('Hours must be greater than zero');
  }
  
  if (entry.hours > MAX_HOURS_PER_DAY) {
    errors.push(`Hours cannot exceed ${MAX_HOURS_PER_DAY} per day`);
  }
  
  if (!entry.account) {
    errors.push('Account is required');
  }
  
  return {
    isValid: errors.length === 0,
    errors
  };
}

// Extracted normalization
function normalizeEntry(entry: TimeEntry): TimeEntry {
  return {
    ...entry,
    account: entry.account.trim().toUpperCase(),
    hours: Math.round(entry.hours * 100) / 100, // 2 decimals
    date: entry.date || formatDate(new Date())
  };
}

// Constants extracted
const MAX_HOURS_PER_DAY = 24;
```

## REFACTOR Phase Workflow

1. **Identify code smell** - Long method? Duplication? Magic numbers?
2. **Make ONE improvement** - Extract method, rename variable, etc.
3. **Run ALL tests** - Must stay GREEN
4. **Commit** - `refactor: extract validation logic`
5. **Repeat** until satisfied

## REFACTOR Phase Checklist

- [ ] Code follows SOLID principles
- [ ] No code duplication (DRY)
- [ ] Clear, descriptive names
- [ ] Appropriate design patterns applied
- [ ] ALL tests still GREEN after each change
- [ ] Code complexity reduced
- [ ] Performance acceptable
- [ ] Changes committed incrementally

## Common Refactoring Techniques

### Extract Method

```csharp
// BEFORE
public void ProcessOrder(Order order)
{
    // Calculate total
    decimal total = 0;
    foreach (var item in order.Items)
        total += item.Price * item.Quantity;
    
    // Apply discount
    if (order.Customer.IsVip)
        total *= 0.9m;
}

// AFTER
public void ProcessOrder(Order order)
{
    var total = CalculateTotal(order.Items);
    total = ApplyDiscount(total, order.Customer);
}

private decimal CalculateTotal(List<OrderItem> items) { }
private decimal ApplyDiscount(decimal total, Customer customer) { }
```

### Extract Value Object

```csharp
// BEFORE: Primitive obsession
public void CreateUser(string email) 
{
    if (!email.Contains("@")) throw new Exception("Invalid email");
}

// AFTER: Value object
public void CreateUser(Email email) { }

public class Email : ValueObject
{
    public string Value { get; }
    
    public static Result<Email> Create(string email)
    {
        if (!email.Contains("@"))
            return Result<Email>.Failure("Invalid email");
        
        return Result<Email>.Success(new Email(email));
    }
}
```

### Remove Duplication (DRY)

```typescript
// BEFORE: Duplication
if (user.age < 18) throw new Error('Must be 18 or older');
if (user.age > 120) throw new Error('Invalid age');

if (manager.age < 18) throw new Error('Must be 18 or older');
if (manager.age > 120) throw new Error('Invalid age');

// AFTER: Extracted function
function validateAge(age: number): void {
  if (age < 18) throw new Error('Must be 18 or older');
  if (age > 120) throw new Error('Invalid age');
}

validateAge(user.age);
validateAge(manager.age);
```

## Tips for REFACTOR Phase

- **Run tests after EVERY change** - Tests are your safety net
- **Make small steps** - One refactor at a time
- **Commit frequently** - Each successful refactor
- **Don't change behavior** - Tests should stay green
- **Trust the tests** - If tests pass, refactor is safe
- **Know when to stop** - Diminishing returns exist
