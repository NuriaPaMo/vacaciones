# Code Generation Prompt

## Agent Reference

> **Primary Agents**:
>
> - [Coding Agent](../copilot/agents/bolt-coding-agent.md) - Code implementation
> - [Micro Iterator](../copilot/agents/bolt-micro-iterator.md) - Iterative development
>
> **Phase**: Block 4 - Construction
> **Constitution**: **CRITICAL** - Read `.boltf/memory/constitution.digest.md` FIRST for tech stack and standards

## Context

Use this prompt when generating production-quality code. This prompt guides Copilot to act as the **Coding Agent** from the Bolt Framework methodology, ensuring clean, testable, and maintainable code.

## Instructions

When generating code:

### 1. Architecture Principles

- Follow Clean Architecture / Hexagonal Architecture
- Separate concerns: Domain, Application, Infrastructure
- Depend on abstractions, not concretions
- Keep domain logic pure and framework-agnostic

### 2. Code Quality Standards

- **SOLID Principles**: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **Clean Code**: Meaningful names, small functions, minimal comments (code should be self-documenting)
- **DRY**: Don't Repeat Yourself, but don't over-abstract
- **KISS**: Keep It Simple, avoid premature optimization

### 3. Error Handling

- Use Result types or discriminated unions for expected failures
- Reserve exceptions for unexpected failures
- Provide meaningful error messages
- Handle errors at appropriate boundaries

### 4. Type Safety

- Prefer strong typing over primitives (Value Objects)
- Use discriminated unions for state machines
- Leverage type inference where clear
- Document public APIs with JSDoc/TSDoc

### 5. Output Format

```typescript
/**
 * [Brief description of the module/class]
 *
 * @example
 * ```typescript
 * // Usage example
 * ```
 */
```

## Examples

### Input

```text
Create a service to handle user registration with email validation
```

### Output

```typescript
// ============================================================================
// Domain Layer
// ============================================================================

// Value Objects
class Email {
  private constructor(private readonly value: string) {}

  static create(email: string): Result<Email, ValidationError> {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return Result.fail(new ValidationError('Invalid email format'));
    }
    return Result.ok(new Email(email));
  }

  toString(): string {
    return this.value;
  }

  equals(other: Email): boolean {
    return this.value === other.value;
  }
}

class Password {
  private constructor(private readonly hashedValue: string) {}

  static create(plainPassword: string): Result<Password, ValidationError> {
    if (plainPassword.length < 8) {
      return Result.fail(new ValidationError('Password must be at least 8 characters'));
    }
    if (!/[A-Z]/.test(plainPassword)) {
      return Result.fail(new ValidationError('Password must contain uppercase letter'));
    }
    if (!/[0-9]/.test(plainPassword)) {
      return Result.fail(new ValidationError('Password must contain a number'));
    }
    // Hash would be done here in real implementation
    const hashed = `hashed:${plainPassword}`; // Placeholder
    return Result.ok(new Password(hashed));
  }

  verify(plainPassword: string): boolean {
    return this.hashedValue === `hashed:${plainPassword}`;
  }
}

// Entity
class User {
  private constructor(
    public readonly id: UserId,
    public readonly email: Email,
    private password: Password,
    public readonly createdAt: Date,
    private _isVerified: boolean = false
  ) {}

  static create(email: Email, password: Password): User {
    return new User(
      UserId.generate(),
      email,
      password,
      new Date(),
      false
    );
  }

  get isVerified(): boolean {
    return this._isVerified;
  }

  verify(): void {
    this._isVerified = true;
  }

  validatePassword(plainPassword: string): boolean {
    return this.password.verify(plainPassword);
  }
}

// Domain Events
class UserRegistered implements DomainEvent {
  constructor(
    public readonly userId: UserId,
    public readonly email: Email,
    public readonly occurredAt: Date = new Date()
  ) {}
}

// ============================================================================
// Application Layer
// ============================================================================

// Ports (Interfaces)
interface UserRepository {
  save(user: User): Promise<void>;
  findByEmail(email: Email): Promise<User | null>;
  exists(email: Email): Promise<boolean>;
}

interface EventPublisher {
  publish(event: DomainEvent): Promise<void>;
}

// DTOs
interface RegisterUserCommand {
  email: string;
  password: string;
}

interface RegisterUserResult {
  userId: string;
  email: string;
}

// Use Case
class RegisterUserUseCase {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly eventPublisher: EventPublisher
  ) {}

  async execute(command: RegisterUserCommand): Promise<Result<RegisterUserResult, RegistrationError>> {
    // 1. Validate email
    const emailResult = Email.create(command.email);
    if (emailResult.isFailure) {
      return Result.fail(new RegistrationError(emailResult.error.message));
    }
    const email = emailResult.value;

    // 2. Check if user exists
    const exists = await this.userRepository.exists(email);
    if (exists) {
      return Result.fail(new RegistrationError('User with this email already exists'));
    }

    // 3. Validate password
    const passwordResult = Password.create(command.password);
    if (passwordResult.isFailure) {
      return Result.fail(new RegistrationError(passwordResult.error.message));
    }
    const password = passwordResult.value;

    // 4. Create user
    const user = User.create(email, password);

    // 5. Persist
    await this.userRepository.save(user);

    // 6. Publish domain event
    await this.eventPublisher.publish(
      new UserRegistered(user.id, user.email)
    );

    // 7. Return result
    return Result.ok({
      userId: user.id.toString(),
      email: user.email.toString()
    });
  }
}

// ============================================================================
// Infrastructure Layer (Adapters)
// ============================================================================

// Repository Implementation
class PostgresUserRepository implements UserRepository {
  constructor(private readonly db: Database) {}

  async save(user: User): Promise<void> {
    await this.db.query(
      `INSERT INTO users (id, email, password_hash, created_at, is_verified)
       VALUES ($1, $2, $3, $4, $5)`,
      [user.id.toString(), user.email.toString(), /* password hash */, user.createdAt, user.isVerified]
    );
  }

  async findByEmail(email: Email): Promise<User | null> {
    const result = await this.db.query(
      'SELECT * FROM users WHERE email = $1',
      [email.toString()]
    );
    return result.rows[0] ? this.mapToUser(result.rows[0]) : null;
  }

  async exists(email: Email): Promise<boolean> {
    const result = await this.db.query(
      'SELECT 1 FROM users WHERE email = $1',
      [email.toString()]
    );
    return result.rowCount > 0;
  }

  private mapToUser(row: any): User {
    // Map database row to User entity
    // Implementation details...
    throw new Error('Not implemented');
  }
}
```

## Constraints

- Never expose domain internals through public APIs
- Always validate inputs at system boundaries
- Use dependency injection for all external dependencies
- Keep functions small (< 20 lines preferred)
- No magic numbers or strings - use constants or enums
- Handle all promise rejections
- Add proper logging at appropriate levels

## Testing Considerations

Generated code should be easily testable:

- Pure functions where possible
- Dependency injection for external services
- Value objects are immutable and comparable
- Domain logic isolated from I/O

## Related Agents

- **Coding Agent**: Primary agent for this prompt
- **Test Inspector Agent**: For test generation
- **Omega Architect Agent**: For architecture decisions

## Bolt Framework Stage

**EXECUTE** → This prompt implements the fifth cognitive stage, transforming designs into working code.
