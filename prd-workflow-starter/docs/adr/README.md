# Architecture Decision Records

Long-lived architectural decisions for this project. ADRs are heavier than PRDs — they describe a **direction** the project is committing to, not a single feature. The ADR is the **why**; the PRD that implements it is the **what** and **when**.

Each ADR has a status (`Proposed`, `Accepted`, `Superseded`, `Deprecated`) and is dated. Numbers are stable. When a decision is reversed, the new ADR supersedes the old one rather than editing it.

Write an ADR when a decision (a) constrains multiple future PRDs, (b) would be expensive or confusing to reverse silently, or (c) settles an argument you don't want to re-litigate. Don't write one for cheaply-reversible choices — note those inline in the PRD instead.

## Index

| # | Status | Title |
|---|---|---|
| 0001 | Accepted | [Documentation is single-source-of-truth, by pointer](0001-documentation-single-source.md) |
