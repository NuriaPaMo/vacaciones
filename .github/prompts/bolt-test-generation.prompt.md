# Test Generation Prompt

## Agent Reference

> **Primary Agent**: [Test Inspector](../copilot/agents/bolt-test-inspector.md)
> **Phase**: Block 4 - Construction
> **Constitution**: Read `.boltf/memory/constitution.digest.md` for testing frameworks and coverage requirements

## Context

Use this prompt when creating tests for the application. This prompt guides Copilot to act as the **Test Inspector Agent** from the Bolt Framework methodology, generating comprehensive test suites using BDD and TDD approaches.

## Instructions

When generating tests:

### 1. Test Strategy

- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test component interactions
- **Contract Tests**: Verify API contracts (Gherkin/Cucumber)
- **End-to-End Tests**: Test complete user workflows

### 2. BDD Approach (Gherkin)

Write specifications in Given-When-Then format:

```gherkin
Feature: [Feature name]
  As a [role]
  I want [capability]
  So that [benefit]

  Scenario: [Scenario name]
    Given [initial context]
    And [additional context]
    When [action]
    Then [expected outcome]
    And [additional outcome]
```

### 3. Test Organization

- Group tests by feature/behavior, not by class
- Use descriptive test names that explain the scenario
- Follow AAA pattern: Arrange, Act, Assert
- One assertion per test (when practical)

### 4. Test Quality

- Test behavior, not implementation
- Cover edge cases and error scenarios
- Use meaningful test data
- Avoid test interdependencies
- Mock external dependencies

### 5. Coverage Goals

- Aim for meaningful coverage, not 100%
- Focus on critical business logic
- Cover all public API contracts
- Test error handling paths

## Examples

### Input

```text
Create tests for the user registration use case
```

### Output

#### Feature File (Gherkin)

```gherkin
# features/user-registration.feature

Feature: User Registration
  As a new visitor
  I want to create an account
  So that I can access personalized features

  Background:
    Given the registration system is available
    And no user exists with email "john@example.com"

  @happy-path
  Scenario: Successful registration with valid data
    Given I am on the registration page
    When I submit registration with:
      | email             | password      |
      | john@example.com  | SecurePass1!  |
    Then my account should be created
    And I should receive a verification email
    And the system should emit a UserRegistered event

  @validation
  Scenario: Registration fails with invalid email
    When I submit registration with:
      | email         | password      |
      | invalid-email | SecurePass1!  |
    Then registration should fail with error "Invalid email format"
    And no account should be created

  @validation
  Scenario: Registration fails with weak password
    When I submit registration with:
      | email            | password |
      | john@example.com | weak     |
    Then registration should fail with error "Password must be at least 8 characters"

  @validation
  Scenario Outline: Password validation rules
    When I submit registration with email "john@example.com" and password "<password>"
    Then registration should fail with error "<error>"

    Examples:
      | password    | error                                      |
      | short       | Password must be at least 8 characters     |
      | nouppercase | Password must contain uppercase letter     |
      | NoNumbers!! | Password must contain a number             |

  @duplicate
  Scenario: Registration fails for existing email
    Given a user exists with email "existing@example.com"
    When I submit registration with:
      | email                 | password      |
      | existing@example.com  | SecurePass1!  |
    Then registration should fail with error "User with this email already exists"
```

#### Unit Tests (TypeScript/Jest)

```typescript
// tests/unit/domain/email.value-object.test.ts

import { Email } from '@/domain/value-objects/email';

describe('Email Value Object', () => {
  describe('create', () => {
    it('should create valid email', () => {
      const result = Email.create('john@example.com');

      expect(result.isSuccess).toBe(true);
      expect(result.value.toString()).toBe('john@example.com');
    });

    it.each([
      ['invalid-email', 'missing @'],
      ['@example.com', 'missing local part'],
      ['john@', 'missing domain'],
      ['john@.com', 'invalid domain'],
      ['', 'empty string'],
    ])('should reject "%s" (%s)', (email, _reason) => {
      const result = Email.create(email);

      expect(result.isFailure).toBe(true);
      expect(result.error.message).toBe('Invalid email format');
    });
  });

  describe('equals', () => {
    it('should be equal for same email', () => {
      const email1 = Email.create('john@example.com').value;
      const email2 = Email.create('john@example.com').value;

      expect(email1.equals(email2)).toBe(true);
    });

    it('should not be equal for different emails', () => {
      const email1 = Email.create('john@example.com').value;
      const email2 = Email.create('jane@example.com').value;

      expect(email1.equals(email2)).toBe(false);
    });
  });
});

// tests/unit/domain/password.value-object.test.ts

import { Password } from '@/domain/value-objects/password';

describe('Password Value Object', () => {
  describe('validation', () => {
    it('should accept valid password', () => {
      const result = Password.create('SecurePass1!');

      expect(result.isSuccess).toBe(true);
    });

    it('should reject password shorter than 8 characters', () => {
      const result = Password.create('Short1!');

      expect(result.isFailure).toBe(true);
      expect(result.error.message).toContain('at least 8 characters');
    });

    it('should reject password without uppercase', () => {
      const result = Password.create('lowercase123!');

      expect(result.isFailure).toBe(true);
      expect(result.error.message).toContain('uppercase');
    });

    it('should reject password without number', () => {
      const result = Password.create('NoNumbersHere!');

      expect(result.isFailure).toBe(true);
      expect(result.error.message).toContain('number');
    });
  });
});

// tests/unit/application/register-user.use-case.test.ts

import { RegisterUserUseCase } from '@/application/use-cases/register-user';
import { UserRepository } from '@/application/ports/user-repository';
import { EventPublisher } from '@/application/ports/event-publisher';

describe('RegisterUserUseCase', () => {
  let useCase: RegisterUserUseCase;
  let mockUserRepository: jest.Mocked<UserRepository>;
  let mockEventPublisher: jest.Mocked<EventPublisher>;

  beforeEach(() => {
    mockUserRepository = {
      save: jest.fn(),
      findByEmail: jest.fn(),
      exists: jest.fn(),
    };
    mockEventPublisher = {
      publish: jest.fn(),
    };
    useCase = new RegisterUserUseCase(mockUserRepository, mockEventPublisher);
  });

  describe('successful registration', () => {
    beforeEach(() => {
      mockUserRepository.exists.mockResolvedValue(false);
    });

    it('should create user and return user id', async () => {
      const result = await useCase.execute({
        email: 'john@example.com',
        password: 'SecurePass1!',
      });

      expect(result.isSuccess).toBe(true);
      expect(result.value.email).toBe('john@example.com');
      expect(result.value.userId).toBeDefined();
    });

    it('should persist user to repository', async () => {
      await useCase.execute({
        email: 'john@example.com',
        password: 'SecurePass1!',
      });

      expect(mockUserRepository.save).toHaveBeenCalledTimes(1);
      expect(mockUserRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          email: expect.anything(),
        })
      );
    });

    it('should publish UserRegistered event', async () => {
      await useCase.execute({
        email: 'john@example.com',
        password: 'SecurePass1!',
      });

      expect(mockEventPublisher.publish).toHaveBeenCalledWith(
        expect.objectContaining({
          email: expect.anything(),
          userId: expect.anything(),
        })
      );
    });
  });

  describe('validation failures', () => {
    it('should fail for invalid email', async () => {
      const result = await useCase.execute({
        email: 'invalid-email',
        password: 'SecurePass1!',
      });

      expect(result.isFailure).toBe(true);
      expect(result.error.message).toContain('Invalid email');
      expect(mockUserRepository.save).not.toHaveBeenCalled();
    });

    it('should fail for weak password', async () => {
      const result = await useCase.execute({
        email: 'john@example.com',
        password: 'weak',
      });

      expect(result.isFailure).toBe(true);
      expect(mockUserRepository.save).not.toHaveBeenCalled();
    });
  });

  describe('duplicate user', () => {
    it('should fail if email already exists', async () => {
      mockUserRepository.exists.mockResolvedValue(true);

      const result = await useCase.execute({
        email: 'existing@example.com',
        password: 'SecurePass1!',
      });

      expect(result.isFailure).toBe(true);
      expect(result.error.message).toContain('already exists');
      expect(mockUserRepository.save).not.toHaveBeenCalled();
    });
  });
});
```

#### Integration Tests

```typescript
// tests/integration/user-registration.test.ts

import { TestDatabase } from '../helpers/test-database';
import { createApp } from '@/infrastructure/app';

describe('User Registration Integration', () => {
  let app: Express;
  let db: TestDatabase;

  beforeAll(async () => {
    db = await TestDatabase.create();
    app = createApp({ database: db.connection });
  });

  afterAll(async () => {
    await db.destroy();
  });

  beforeEach(async () => {
    await db.truncate('users');
  });

  it('should register user via API', async () => {
    const response = await request(app)
      .post('/api/users/register')
      .send({
        email: 'integration@example.com',
        password: 'SecurePass1!',
      });

    expect(response.status).toBe(201);
    expect(response.body.userId).toBeDefined();

    // Verify in database
    const user = await db.query('SELECT * FROM users WHERE email = $1', ['integration@example.com']);
    expect(user.rows).toHaveLength(1);
  });
});
```

## Test Patterns

### Test Doubles

- **Mock**: Verify interactions (e.g., method was called)
- **Stub**: Return predefined values
- **Fake**: Working implementation for tests (e.g., in-memory repository)
- **Spy**: Record calls while delegating to real implementation

### Test Data

```typescript
// tests/fixtures/users.ts
export const validUserData = {
  email: 'test@example.com',
  password: 'ValidPass123!',
};

export const createUserFixture = (overrides = {}) => ({
  ...validUserData,
  ...overrides,
});
```

## Constraints

- Tests must be independent and repeatable
- Clean up test data after each test
- Use factories/fixtures for test data
- Mock at appropriate boundaries
- Avoid testing private methods directly
- Don't test framework code

## Related Agents

- **Test Inspector Agent**: Primary agent for this prompt
- **Coding Agent**: For implementation under test
- **Policy Guardian Agent**: For compliance testing

## Bolt Framework Stage

**VALIDATE** → This prompt implements the sixth cognitive stage, verifying that implementations meet requirements.
