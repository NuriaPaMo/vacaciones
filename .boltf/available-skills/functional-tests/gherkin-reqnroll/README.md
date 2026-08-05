# Gherkin & Reqnroll BDD Testing Skill

Este skill proporciona guías completas y mejores prácticas para escribir tests de aceptación usando
Gherkin y Reqnroll en proyectos .NET con Bolt Framework.

## ¿Por qué este skill?

- **Requisitos ejecutables**: Convierte user stories en tests ejecutables
- **Colaboración**: Lenguaje común entre stakeholders técnicos y no técnicos
- **Documentación viva**: Las especificaciones Gherkin documentan el comportamiento del sistema
- **Reqnroll**: Sucesor moderno de SpecFlow para .NET

## Ejemplos de Uso

### Ejemplo 1: Generar Feature desde User Story

**Input al Copilot:**

```text
Genera un archivo Gherkin para el user story US-001 de autenticación
```

**Copilot cargará este skill y generará:**

- Feature file con sintaxis Gherkin correcta
- Escenarios mapeados a acceptance criteria
- Tags apropiados (@US-001, @AC-001.1, etc.)
- Step definitions skeleton en C#

### Ejemplo 2: Crear Step Definitions para Feature Existente

**Input al Copilot:**

```text
Genera step definitions para el feature Authentication.feature
```

**Copilot generará:**

- Clase C# con atributo `[Binding]`
- Métodos con atributos `[Given]`, `[When]`, `[Then]`
- Implementación usando ScenarioContext
- Integración con WebApplicationFactory para tests

### Ejemplo 3: Convertir Acceptance Criteria en Scenario Outline

**Input al Copilot:**

```text
Convierte estos acceptance criteria en un Scenario Outline:
- Email vacío → Error "Email is required"
- Email inválido → Error "Invalid email format"
- Password vacío → Error "Password is required"
```

**Copilot generará:**

```gherkin
Scenario Outline: Validate login form fields
  Given I am on the login page
  When I enter email "<email>"
  And I enter password "<password>"
  And I submit the form
  Then I should see error "<error_message>"

  Examples:
    | email              | password    | error_message         |
    |                    | password123 | Email is required     |
    | invalid-email      | password123 | Invalid email format  |
    | user@example.com   |             | Password is required  |
```

## Integración con Bolt Framework

Este skill se integra con:

- **@Bolt Framework Gherkin**: Agente especializado en generar Gherkin
- **@Bolt Framework Testing**: Agente para ejecutar tests
- **Constitution**: Lee reglas de testing del proyecto
- **Feature Specs**: Extrae acceptance criteria de `specs/*/requirements/`

## Archivos Relacionados

- [SKILL.md](./SKILL.md) - Instrucciones principales
- [../skill-backend-testing-dotnet](../skill-backend-testing-dotnet/) - Testing backend relacionado
- [../../agents/bolt-gherkin.agent.md](../../agents/bolt-gherkin.agent.md) - Agente Gherkin

## Referencias

- [Reqnroll Documentation](https://docs.reqnroll.net/)
- [Gherkin Reference](https://cucumber.io/docs/gherkin/reference/)
- [BDD Best Practices](https://cucumber.io/docs/bdd/)
