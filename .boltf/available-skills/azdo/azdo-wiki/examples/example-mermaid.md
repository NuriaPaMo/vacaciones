# Example: Architecture with Mermaid Diagram

This document demonstrates how Mermaid diagrams are converted when syncing to Azure DevOps wiki.

## System Architecture

The Registro Horario application follows a clean architecture pattern:

```mermaid
graph TB
    subgraph Frontend
        Angular[Angular App]
        Apollo[Apollo Client]
    end

    subgraph Backend
        API[API Gateway]
        Auth[Authentication]
        TimeEntry[Time Entry Module]
        Reporting[Reporting Module]
    end

    subgraph Data
        DB[(SQL Database)]
        Cache[(Redis Cache)]
    end

    Angular --> Apollo
    Apollo --> API
    API --> Auth
    API --> TimeEntry
    API --> Reporting
    TimeEntry --> DB
    Reporting --> DB
    Auth --> Cache
```

## Component Flow

When a user logs time, the following sequence occurs:

```mermaid
sequenceDiagram
    participant User
    participant UI as Angular UI
    participant API as API Gateway
    participant Auth as Auth Service
    participant TimeEntry as Time Entry Service
    participant DB as Database

    User->>UI: Enter time entry
    UI->>API: POST /api/timeentries
    API->>Auth: Validate token
    Auth-->>API: Token valid
    API->>TimeEntry: Create entry
    TimeEntry->>DB: INSERT
    DB-->>TimeEntry: Success
    TimeEntry-->>API: Entry created
    API-->>UI: 201 Created
    UI-->>User: Confirmation
```

## Data Model

```mermaid
erDiagram
    Employee ||--o{ TimeEntry : logs
    TimeEntry ||--|| QuinceCount : "belongs to"
    Employee ||--o{ CuentaCargo : "assigned to"

    Employee {
        int EmployeeId PK
        string Name
        string Email
        string EntraIdObjectId
    }

    TimeEntry {
        int TimeEntryId PK
        int EmployeeId FK
        int QuinceId FK
        int CuentaCargoId FK
        date EntryDate
        decimal Hours
    }

    QuinceCount {
        int QuinceId PK
        date StartDate
        date EndDate
        bool IsOpen
    }

    CuentaCargo {
        int CuentaCargoId PK
        string Code
        string Description
    }
```

## After Conversion

When this document is synced to Azure DevOps wiki using `Sync-DocsToWiki.ps1`, the script will:

1. **Extract the 3 Mermaid diagrams** from the code blocks
2. **Convert each to SVG**:
   - `example-diagram-1.svg` (architecture graph)
   - `example-diagram-2.svg` (sequence diagram)
   - `example-diagram-3.svg` (ER diagram)
3. **Replace Mermaid blocks** with image references:

   ```markdown
   ![Diagram 1](/.attachments/example-diagram-1.svg)
   ```

4. **Upload SVGs** to wiki's `.attachments/` folder
5. **Create/update** the wiki page with processed content

## Manual Conversion Test

To test Mermaid conversion manually:

````powershell
# Extract first diagram
$content = Get-Content "example-mermaid.md" -Raw
$pattern = '(?s)```mermaid\s+(.*?)```'
$match = [regex]::Match($content, $pattern)

if ($match.Success) {
    # Save to temp file
    $match.Groups[1].Value | Out-File "temp.mmd" -Encoding UTF8

    # Convert
    mmdc -i temp.mmd -o test-diagram.svg -t dark -b transparent -s 2

    # View result
    Start-Process test-diagram.svg
}
````

## Additional Information

This example is used to:

- **Test** the Mermaid conversion workflow
- **Demonstrate** different diagram types (graph, sequence, ER)
- **Validate** SVG generation quality
- **Document** the conversion process

For more details, see the [SKILL.md](../SKILL.md) documentation.
