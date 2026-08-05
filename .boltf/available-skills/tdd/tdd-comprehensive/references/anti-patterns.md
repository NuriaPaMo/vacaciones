# Anti-Patterns - Why Test-First Matters

## The Test-First Discipline

### Why the Order Matters

**Test-First (TDD):**

```text
1. Write failing test
2. Watch it fail
3. Write minimal code
4. Watch it pass
5. Refactor
```

**Test-After (NOT TDD):**

```text
1. Write implementation
2. Write test
3. Test passes immediately
4. ???? (Did test prove anything?)
```

### The Problem with Test-After

When you write tests after implementation:

1. **Bias toward implementation** - Test verifies what code does, not what it should do
2. **False confidence** - Passing test doesn't prove it catches bugs
3. **Missing edge cases** - Forgot to test failure paths
4. **Never saw it fail** - Don't know if test actually works

### Proof Tests Work: Watch Them Fail

**Good Example:**

```typescript
// Step 1: Write test
test('divides two numbers', () => {
  expect(divide(10, 2)).toBe(5);
});

// Step 2: Run test - MUST SEE THIS:
// ❌ FAIL: ReferenceError: divide is not defined

// Step 3: Implement
function divide(a: number, b: number): number {
  return a / b;
}

// Step 4: Run test
// ✅ PASS: divides two numbers
```

Now we KNOW the test works because we saw it fail when code was missing.

**Bad Example:**

```typescript
// Step 1: Write implementation
function divide(a: number, b: number): number {
  return a / b;
}

// Step 2: Write test
test('divides two numbers', () => {
  expect(divide(10, 2)).toBe(5);
});

// Step 3: Run test
// ✅ PASS: divides two numbers

// Problem: Test passed immediately. Does it catch bugs?
```

We never saw this test fail. Does it actually test anything?

## Common Rationalizations (and Why They're Wrong)

### "I'll write tests after to verify it works"

**The claim:** "I wrote the code, it works. Now I'll add tests to verify."

**Why it's wrong:**

- Tests passing immediately prove nothing
- You're testing what code DOES, not what it SHOULD do
- Confirmation bias - miss edge cases, don't test failure paths
- "Verification tests" catch nothing

**Reality check:**

```typescript
// You wrote this:
function calculateTax(amount: number): number {
  return amount * 0.1; // 10% tax
}

// Then wrote this test:
test('calculates tax', () => {
  expect(calculateTax(100)).toBe(10); // ✅ Passes
});

// But you forgot to test:
test('handles negative amounts', () => {
  expect(() => calculateTax(-100)).toThrow(); // ❌ FAILS - no validation!
});

test('handles zero', () => {
  expect(calculateTax(0)).toBe(0); // ✅ Passes (by luck)
});

test('handles decimals', () => {
  expect(calculateTax(99.99)).toBeCloseTo(9.999, 2); // Who knows?
});
```

**Solution:** Test FIRST. Let tests define requirements.

### "Already manually tested it, works fine"

**The claim:** "I tested it in the browser/Postman/debugger. It works."

**Why it's wrong:**

- Manual testing is ad-hoc, no record
- "It worked when I tried it" ≠ comprehensive testing
- Can't re-run manual tests after refactor
- Miss edge cases you didn't think to test

**Reality check:**
You tested:

- ✅ Happy path with valid data
- ❌ Null inputs
- ❌ Empty strings
- ❌ Boundary values
- ❌ Concurrent operations
- ❌ Error conditions

**Solution:** Automated tests are systematic and repeatable.

### "Deleting hours of work is wasteful"

**The claim:** "I spent 3 hours building this. You want me to DELETE it and start over with TDD? That's wasteful!"

**Why it's wrong:**

- Sunk cost fallacy
- Code without tests = technical debt
- Bugs will cost more time later
- Rewriting with TDD is FASTER than debugging later

**Reality:**

```text
Time spent: 3 hours implementation (no tests)
Time to debug prod issues: 5 hours
Time fixing bugs: 4 hours
Time adding tests after: 2 hours
Total: 14 hours

VS

Time spent: 4 hours TDD implementation
Time to debug prod issues: 0 hours
Time fixing bugs: 0 hours
Total: 4 hours
```

**Solution:** Delete it. Rewrite with TDD. Build it right the first time.

### "TDD will slow me down"

**The claim:** "Writing tests first takes too long. I need to ship fast."

**Why it's wrong:**

- TDD PREVENTS slow debugging sessions
- Quick and buggy ≠ fast
- Refactoring without tests is terrifying
- Production bugs are expensive

**Time comparison:**

```text
No TDD:
- Write code: 2 hours
- QA finds bugs: 1 hour
- Debug: 3 hours
- Fix: 1 hour
- Retest: 1 hour
- Production bug: 2 hours
- Emergency fix: 4 hours
Total: 14 hours

TDD:
- Write tests + code: 4 hours
- Bugs found: minimal
- Debug: minimal
- Production bugs: rare
Total: 5 hours
```

**Solution:** TDD IS fast. Debugging is slow.

### "This code is too simple for TDD"

**The claim:** "It's just a simple getter/setter. No need for tests."

**Why it's wrong:**

- Simple code breaks too
- "Simple" code becomes complex
- No code is too simple to break
- Tests document behavior

**Reality check:**

```typescript
// "Simple" code
class User {
  private _email: string;

  setEmail(email: string) {
    this._email = email; // "Works" but...
  }

  getEmail(): string {
    return this._email;
  }
}

// Bugs in "simple" code:
// - No validation
// - Accepts invalid emails
// - Accepts null/undefined
// - No trimming
// - Case sensitivity issues
```

**Solution:** Test everything. Complex or simple.

### "It's just a prototype/experiment"

**The claim:** "This is exploratory code. I'll add tests if we actually use it."

**Why it's wrong:**

- Prototypes become production (they always do)
- "Temporary" code is the most permanent
- When it works, no one will rewrite it
- "Just testing an idea" → "Ship it"

**Reality:**

```text
Week 1: "Let me quickly prototype this..."
Week 2: "Cool, it works! Let's add features."
Month 2: "This is powering 50% of our traffic."
Month 3: "Why does it keep breaking?"
Month 4: "We can't refactor, too risky."
Year 1: "Legacy code we're afraid to touch."
```

**Solution:** Delete the prototype. Build it properly with TDD.

## Red Flags - When TDD Isn't Happening

### Code Review Red Flags

- 🚩 Test passes on first run (never saw it fail)
- 🚩 Test file timestamp AFTER implementation file
- 🚩 Commit message "fix tests" after "implement feature"
- 🚩 Test only covers happy path
- 🚩 No edge case tests
- 🚩 Coverage added to pass CI threshold
- 🚩 Tests mirror implementation exactly

### Team Red Flags

- 🚩 "I'll add tests later" (they won't)
- 🚩 "Tests are too slow" (they're not writing unit tests)
- 🚩 "TDD doesn't work for X" (they haven't tried)
- 🚩 "We don't have time for tests" (you'll spend 2× debugging)
- 🚩 Frequent production bugs in "tested" code
- 🚩 Afraid to refactor
- 🚩 Coverage metric gaming

## Enforcement Strategies

### 1. Watch Test Fail Rule

**Requirement:** Before committing, prove test failed first.

```bash
# Good commit history:
commit 1: "test: add failing test for user registration validation"
commit 2: "feat: implement user registration validation"
commit 3: "refactor: extract validation helpers"

# Bad commit history:
commit 1: "feat: implement user registration with validation"
commit 2: "test: add tests for user registration" ❌
```

### 2. Pair Programming

Junior writes test → Senior reviews → Junior implements → Senior reviews

Ensures test-first discipline from day one.

### 3. Coverage Requirement

**Minimum: 80% line coverage**

But not just any coverage:

```typescript
// ❌ BAD: Coverage without quality
function divide(a: number, b: number): number {
  if (b === 0) throw new Error('Division by zero');
  return a / b;
}

test('divides numbers', () => {
  expect(divide(10, 2)).toBe(5); // Only happy path
});
// Coverage: 66% (missing error path)

// ✅ GOOD: Comprehensive coverage
test('divides numbers', () => {
  expect(divide(10, 2)).toBe(5);
});

test('throws on division by zero', () => {
  expect(() => divide(10, 0)).toThrow('Division by zero');
});
// Coverage: 100%
```

### 4. Pre-Commit Hooks

```json
{
  "husky": {
    "hooks": {
      "pre-commit": "npm test && npm run test:coverage"
    }
  }
}
```

Prevents committing code without passing tests and coverage.

### 5. CI/CD Enforcement

```yaml
# .github/workflows/test.yml
- name: Run tests
  run: npm test

- name: Check coverage
  run: npm run test:coverage

- name: Fail if under 80%
  run: npx nyc check-coverage --lines 80 --functions 80 --branches 80
```

Build fails if coverage drops below threshold.

### 6. Code Review Checklist

- [ ] Test commit before implementation commit?
- [ ] Test failure visible in PR?
- [ ] Edge cases tested?
- [ ] Error paths tested?
- [ ] Coverage meets threshold?
- [ ] No test-after patterns?

## The Iron Law Restated

**NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST**

This means:

1. ✅ Write test
2. ✅ Watch it **FAIL**
3. ✅ Write code
4. ✅ Watch it **PASS**
5. ✅ Refactor

Not:

1. ❌ Write code
2. ❌ Write test
3. ❌ Everything passes
4. ❌ ????

**Violating the letter is violating the spirit.**

## Conclusion

Test-first TDD is not optional. It's not a suggestion. It's not "when we have time."

The order matters:

- Test-first = unbiased requirements testing
- Test-after = biased implementation verification

Which would you trust to catch bugs?
