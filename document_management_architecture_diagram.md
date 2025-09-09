# Document Management System Architecture Diagram

```mermaid
graph TD
    A[User Interface] --> B[Document Service]
    B --> C[Database Layer]
    B --> D[Storage Layer]
    
    subgraph "User Interface"
        A1[Student Documents Screen]
        A2[Teacher Document Dashboard]
        A3[Admin Document Management]
        A4[Document Preview Component]
        A5[Document Send Dialog]
    end
    
    subgraph "Document Service"
        B1[Document Operations]
        B2[File Management]
        B3[User Permissions]
        B4[Search & Filter]
        B5[Analytics Tracking]
    end
    
    subgraph "Database Layer"
        C1[Documents Table]
        C2[Student Documents Table]
        C3[Document Categories]
        C4[Document Activities]
        C5[Database Functions]
    end
    
    subgraph "Storage Layer"
        D1[Supabase Storage]
        D2[Documents Bucket]
        D3[File Metadata]
    end
    
    A1 --> B1
    A2 --> B1
    A3 --> B1
    A4 --> B2
    A5 --> B1
    A5 --> B2
    
    B1 --> C1
    B1 --> C2
    B1 --> C3
    B2 --> D1
    B4 --> C1
    B5 --> C4
    
    C1 --> C5
    C2 --> C5
    C3 --> C5
```

This diagram shows the key components of the new document management system and their relationships:

1. **User Interface Layer**: Contains all the screens and components that users interact with
2. **Document Service Layer**: The core business logic for document management
3. **Database Layer**: All database tables and functions that store document metadata
4. **Storage Layer**: The file storage system where actual document files are stored

The arrows indicate the flow of data and interactions between components.