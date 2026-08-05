# Common Scope Constitution Articles

This scope provides universal skills applicable to all Bolt Framework projects.

## Article XXI: Documentation Standards

### Markdown Formatting

All documentation MUST follow CommonMark specification:

- **Single H1 per document** (title only)
- **Code blocks** with language specifiers (typescript, bash, etc.)
- **Consistent list formatting** (- for unordered, 1. for ordered)
- **Proper link formatting** ([text](url))
- **Tables** with alignment markers

Rationale:

- Consistent documentation improves maintainability
- Markdown linting prevents formatting issues
- Clear standards reduce review friction

Tool Support:

- Skill: `markdown-formatting` (auto-provisioned)
- Linters: markdownlint, markdown-link-check
- Conventions: BOLT Framework-specific extensions documented in skill

## Article XXII: Test-Driven Development

### TDD Discipline

All production code MUST be preceded by failing tests:

1. **RED**: Write failing test first
2. **GREEN**: Write minimal code to pass
3. **REFACTOR**: Improve without changing behavior

Coverage Requirements:

- **Unit tests**: Minimum 80% line coverage
- **Integration tests**: Critical paths covered
- **Acceptance tests**: User stories validated (BDD)

Rationale:

- Prevents untestable code
- Documents expected behavior
- Enables confident refactoring
- Reduces bug density

Tool Support:

- Skill: `tdd-comprehensive` (auto-provisioned)
- Patterns: Red-Green-Refactor, Test Pyramid
- BDD: Gherkin scenarios with `gherkin-reqnroll` skill

### Behavior-Driven Development (BDD)

Acceptance criteria SHOULD be expressed as Gherkin scenarios when:

- Feature involves multiple stakeholders
- Business rules are complex
- Executable specifications provide value
- .NET stack (Reqnroll support)

Format:

```gherkin
Feature: User Authentication
  As a registered user
  I want to log in with credentials
  So that I can access my account

  @AC-001
  Scenario: Successful login
    Given a user with valid credentials
    When they submit the login form
    Then they should be redirected to dashboard
    And a session cookie should be set
```

Tool Support:

- Skill: `gherkin-reqnroll` (auto-provisioned)
- Framework: Reqnroll (SpecFlow successor for .NET)
- Integration: Links to feature specs in `specs/` directory

## Notes

These articles are merged into every project constitution, regardless of Practice or scopes selected. They represent **universal best practices** for Bolt Framework projects.
