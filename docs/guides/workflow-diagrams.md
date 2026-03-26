# Weather App Development Workflow Diagrams

Visual reference for the development workflow (v2.0.0).

---

## 1. Two-Session Development Flow

```mermaid
flowchart TB
    subgraph SessionA["Session A: Planning"]
        PF["/design-feature"] --> INT["Stage 1: Interview"]
        INT --> RES["Stage 2: Research"]
        RES --> DES["Stage 3: Design"]
        DES --> DOC["Stage 4: Document"]
        DOC --> CT["Stage 5: Create Tasks"]
        CT --> STOP["Stage 6: STOP"]
    end

    subgraph Review["User Review"]
        STOP --> REV{"Review\nArtifacts?"}
        REV -->|Approved| IMPL
        REV -->|Changes| INT
    end

    subgraph SessionB["Session B: Implementation"]
        IMPL["/dev-feature"] --> GATHER["Gather Context"]
        GATHER --> PLAN["Build Plan"]
        PLAN --> APPROVE{"User\nApproves?"}
        APPROVE -->|No| PLAN
        APPROVE -->|Yes| BATCH["Execute Batches"]
        BATCH --> REVIEW["Review + QA"]
        REVIEW --> PR["Create PR"]
        PR --> UPDATE["Update Tracker"]
    end

    style STOP fill:#ff9,stroke:#333
    style APPROVE fill:#ff9,stroke:#333
```

---

## 2. Design-Feature: 6 Phases

```mermaid
flowchart LR
    subgraph P0["Stage 0"]
        MARKER[".planning-session"]
    end

    subgraph P1["Stage 1"]
        INTERVIEW["Interview\n(MANDATORY)"]
    end

    subgraph P2["Stage 2"]
        RESEARCH["Research"]
    end

    subgraph P3["Stage 3"]
        DESIGN["Design"]
    end

    subgraph P4["Stage 4"]
        DOCS["Document Suite\n(8 types)"]
    end

    subgraph P5["Stage 5"]
        TASKS["Epic + Issues"]
    end

    subgraph P6["Stage 6"]
        STOP["STOP"]
    end

    P0 --> P1 --> P2 --> P3 --> P4 --> P5 --> P6

    style P6 fill:#ff9,stroke:#333
```

---

## 3. Develop-Feature: Batch Execution

```mermaid
flowchart TB
    START["Gather Context"] --> PLAN["Build Dependency Graph"]
    PLAN --> APPROVE{"User Approves?"}
    APPROVE -->|No| REVISE["Revise Plan"]
    REVISE --> APPROVE
    APPROVE -->|Yes| B1

    subgraph B1["Batch 1: Database"]
        DB["DB- tasks"] --> DBS["database-specialist"]
    end

    subgraph B2["Batch 2: Backend"]
        BE["BE- tasks"] --> BED["backend-developer"]
    end

    subgraph B3["Batch 3: Frontend/Bot"]
        FE["FE-/BOT-/UI- tasks"] --> FED["frontend-developer\nbot-developer"]
    end

    subgraph B4["Batch 4: Documentation"]
        DOC["DOC- tasks"] --> TW["technical-writer"]
    end

    subgraph B5["Batch 5: QA"]
        QA["QA- tasks"] --> IQA["integration-qa"]
    end

    B1 --> B2 --> B3 --> B4 --> B5

    B5 --> REVIEW["Code Review + Security"]
    REVIEW --> PR["Create PR per repo"]
```

---

## 4. Develop-Task: 10-Step TDD

```mermaid
flowchart TB
    S1["1. Setup Branch"] --> S2["2. Gather Context"]
    S2 --> S3["3. Plan (USER APPROVAL)"]
    S3 --> S4["4. TDD Red (failing tests)"]
    S4 --> S5["5. Develop (agent dispatch)"]
    S5 --> S6["6. Code Simplifier"]
    S6 --> S7["7. Review Gates (parallel)"]

    subgraph S7Detail["Step 7: Parallel Reviews"]
        QG["Quality Gates"]
        CR["Code Review"]
        SEC["Security Review"]
    end

    S7 --> S8["8. QA Verification"]
    S8 --> S9["9. Commit + PR (STOP)"]
    S9 --> S10["10. Update Tracker"]

    S7 -->|Fail| S5

    style S3 fill:#ff9,stroke:#333
    style S9 fill:#ff9,stroke:#333
```

---

## 5. Branch Hierarchy

```mermaid
gitGraph
    commit id: "initial"
    branch dev
    checkout dev
    commit id: "dev-setup"

    branch feat/WA-100-feature
    checkout feat/WA-100-feature
    commit id: "DB-001"
    commit id: "BE-001"
    commit id: "FE-001"

    checkout dev
    merge feat/WA-100-feature id: "feature-pr"

    checkout main
    merge dev id: "release-v1.0.0" tag: "v1.0.0"
```

---

## 6. Agent Assignment

```mermaid
flowchart LR
    subgraph Tasks["Task Prefixes"]
        DB["DB-XXX"]
        BE["BE-XXX"]
        FE["FE-XXX"]
        UI["UI-XXX"]
        BOT["BOT-XXX"]
        DOC["DOC-XXX"]
        INFRA["INFRA-XXX"]
        SEC["SEC-XXX"]
        QA["QA-XXX"]
    end

    subgraph Developers["Developer Agents"]
        DBS["database-specialist"]
        BED["backend-developer"]
        FED["frontend-developer"]
        FDD["frontend-designer"]
        BOTD["bot-developer"]
        TW["technical-writer"]
        DE["devops-engineer"]
        SS["security-specialist"]
        IQA["integration-qa"]
    end

    subgraph Reviewers["Reviewer Agents"]
        BER["backend-reviewer"]
        FER["frontend-reviewer"]
    end

    DB --> DBS --> BER
    BE --> BED --> BER
    FE --> FED --> FER
    UI --> FDD --> FER
    BOT --> BOTD --> BER
    DOC --> TW
    INFRA --> DE --> BER
    SEC --> SS
    QA --> IQA
```

---

## 7. Hook Architecture

```mermaid
flowchart TB
    subgraph PreToolUse["PreToolUse Hooks"]
        PF["protect-files.sh\n(Edit/Write)"]
        DS["detect-secrets.sh\n(Bash)"]
        HA["hitl-approval.sh\n(Bash)"]
        PG["planning-guard.sh\n(Task)"]
    end

    subgraph PostToolUse["PostToolUse Hooks"]
        AL["audit-log.sh\n(all tools)"]
        CS["checkpoint-save.sh\n(Edit/Write)"]
        ME["mcp-error-detect.sh\n(all tools)"]
    end

    subgraph PostToolUseFailure["PostToolUseFailure"]
        ED["error-detect.sh\n(all tools)"]
    end

    subgraph SessionStart["SessionStart"]
        SB["stale-branch.sh"]
        CR["context-recovery.sh"]
    end

    subgraph PreCompact["PreCompact"]
        PC["pre-compact.sh"]
    end

    subgraph Stop["Stop"]
        SE["session-end-reminder.sh"]
    end
```

---

## 8. Context Recovery Flow

```mermaid
flowchart TB
    subgraph SessionStart["Session Start"]
        CR["context-recovery.sh fires"]
    end

    CR --> CP{"Checkpoint\nexists?"}
    CP -->|Yes| LOAD_CP["Load .checkpoint"]
    CP -->|No| HO{"Handover\nexists?"}

    LOAD_CP --> HO
    HO -->|Yes| LOAD_HO["Load latest handover"]
    HO -->|No| FRESH["Fresh session"]

    LOAD_HO --> RESUME["Resume at last known state"]
    LOAD_CP --> RESUME

    subgraph PreCompact["Before Context Compression"]
        PC["pre-compact.sh fires"]
        PC --> SAVE_HO["Save handover to .claude/handovers/"]
    end
```

---

**Version**: 2.0.0
**Template**: Workflow Diagrams
