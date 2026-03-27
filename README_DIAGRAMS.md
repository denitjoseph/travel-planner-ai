# System Architecture & Diagrams

This document contains the structural, behavioral, and architectural diagrams for the **TravelAI** system.

## 1. ER Diagram (Entity Relationship)
Shows entities, attributes, and relationships.

```mermaid
erDiagram
    USER {
        string id PK
        string name
        string email
        string preferences
    }
    TRIP {
        string id PK
        string userId FK
        string destination
        date startDate
        date endDate
        float budget
    }
    ITINERARY {
        string id PK
        string tripId FK
        string aiProvider
        json dailyPlan
        json hotels
    }
    USER ||--o{ TRIP : "creates"
    TRIP ||--|| ITINERARY : "contains"
```

## 2. DFD Level 0 (Context Diagram)
Shows overall system data flow.

```mermaid
flowchart TD
    U[User] -->|Trip Preferences| S((TravelAI System))
    A[Admin] -->|Config/Updates| S
    S -->|Generated Itinerary, Map Data| U
    S -->|API Requests| EXT[External Services: Gemini, Google Maps, Firebase]
    EXT -->|Responses| S
```

## 3. DFD Level 1
Shows detailed data flow between modules.

```mermaid
flowchart TD
    U[User] -->|Authentication Data| P1(1.0 Auth/Login)
    P1 -->|Token| DB[(Firebase DB)]
    U -->|Trip Parameters| P2(2.0 Process Request)
    P2 -->|Parameters| P3(3.0 Connect External APIs)
    P3 <-->|Query & Data| EXT[External Services]
    P3 -->|Raw Itinerary| P4(4.0 Format & Generate)
    P4 -->|Final Output| DB
    P4 -->|Display Itinerary| U
    A[Admin] -->|Management| P5(5.0 System Config)
    P5 <--> DB
```

## 4. DFD Level 1.1 (Admin)
Shows admin-specific data flow.

```mermaid
flowchart TD
    A[Admin] -->|Credentials| P1(1.1.1 Authenticate Admin)
    P1 <--> DB[(Database)]
    A -->|API Key Updates| P2(1.1.2 Manage Backend Config)
    P2 --> DB
    A -->|Request Logs| P3(1.1.3 View Analytics)
    DB -->|Log Data| P3
    P3 --> A
```

## 5. DFD Level 1.2 (User)
Shows user/customer-specific data flow.

```mermaid
flowchart TD
    U[User] -->|Location/Dates| P1(1.2.1 Request Itinerary)
    P1 --> P2(1.2.2 Fetch AI Suggestions)
    P2 --> P3(1.2.3 Fetch Map Routing)
    P3 --> P4(1.2.4 Compile Result)
    P4 -->|Save| DB[(Firebase DB)]
    P4 -->|Show UI| U
    U -->|Chat Input| P5(1.2.5 AI Assistant)
    P5 -->|Voice/Text| U
```

## 6. Use Case Diagram
Shows interactions between Admin and User with the system.

```mermaid
flowchart LR
    subgraph TravelAI System
        UC1(Sign in / Sign up)
        UC2(Generate Trip Itinerary)
        UC3(Chat with Assistant)
        UC4(Export to PDF / WhatsApp)
        UC5(Manage API Keys)
        UC6(View System Logs)
    end
    User --> UC1
    User --> UC2
    User --> UC3
    User --> UC4
    Admin --> UC1
    Admin --> UC5
    Admin --> UC6
```

## 7. Activity Diagram (Swim Lane)
Shows flow of activities across roles.

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant Backend
    participant AI_Service
    participant DB

    User->>Frontend: Enter Trip Details
    Frontend->>Backend: API Request (/generate)
    Backend->>DB: Log Request
    Backend->>AI_Service: Forward Prompt
    AI_Service-->>Backend: Return JSON Itinerary
    Backend->>DB: Save Generated Data
    Backend-->>Frontend: Output Data
    Frontend-->>User: Display Premium UI Cards
```

## 8. Class Diagram (UML)
Shows classes, attributes, methods, and relationships.

```mermaid
classDiagram
    class User {
        +String id
        +String name
        +String email
        +login()
        +logout()
    }
    class Trip {
        +String tripId
        +String destination
        +int days
        +generatePlan()
    }
    class APIHandler {
        +String apiKey
        +fetchGemini()
        +fetchMaps()
    }
    class ChatBot {
        +String context
        +sendPrompt()
        +speechToText()
    }
    User "1" -- "*" Trip : owns
    Trip "1" -- "1" APIHandler : uses
    Trip "1" -- "1" ChatBot : interacts
```

## 9. Schema Diagram
Shows database tables, primary keys, foreign keys.

```mermaid
erDiagram
    users {
        string uid PK
        string email
        timestamp lastLogin
    }
    trips {
        string trip_id PK
        string uid FK
        string destination
        int duration_days
    }
    messages {
        string msg_id PK
        string trip_id FK
        string sender
        string content
    }
    users ||--o{ trips : "has"
    trips ||--o{ messages : "history"
```

## 10. Sequence Diagram
Shows message flow between objects over time.

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant App as Flutter App
    participant API as Flask Backend
    participant Gemini as AI Model
    
    U->>App: Click "Generate Itinerary"
    App->>API: POST /api/plan (Location, Budget)
    API->>Gemini: Request context generation
    Gemini-->>API: JSON structure (Hotels, Places)
    API-->>App: Parsed Data
    App-->>U: Render Shimmer loading, then UI
```

## 11. Structure Chart
Shows module hierarchy and relationships.

```mermaid
flowchart TD
    Root[TravelAI App]
    Root --> UI[UI Layer]
    Root --> BL[Business Logic Layer]
    Root --> DL[Data Layer]
    
    UI --> Screens[Screens: Plan, Result, Chat]
    UI --> Widgets[Widgets: Cards, Glassmorphism]
    
    BL --> State[State Management]
    BL --> Handlers[API/AI Handlers]
    
    DL --> FB[Firebase Services]
    DL --> Ext[External REST APIs]
```

## 12. Gantt Chart
Shows project timeline and task schedule.

```mermaid
gantt
    title TravelAI Development Timeline
    dateFormat  YYYY-MM-DD
    section Phase 1: Planning
    Requirements & Diagrams    :done,    des1, 2023-10-01, 7d
    UI/UX Design Mockups       :done,    des2, 2023-10-08, 7d
    section Phase 2: Core
    Flutter Skeleton           :active,  dev1, 2023-10-15, 10d
    Flask Backend Setup        :active,  dev2, 2023-10-15, 10d
    Integration & APIs         :         dev3, 2023-10-25, 14d
    section Phase 3: Polish
    Voice feature (TTS)        :         dev4, 2023-11-08, 7d
    Testing & Debugging        :         test1, 2023-11-15, 7d
```

## 13. PERT Chart
Shows task dependencies and critical path.

```mermaid
flowchart TD
    A((Start)) --> B(UI Design)
    A --> C(Backend Setup)
    B --> D(Mobile App Dev)
    C --> E(API Integration)
    D --> F(Merge Frontend/Backend)
    E --> F
    F --> G(Add Voice AI)
    G --> H(Final Testing)
    H --> I((Launch))
```
