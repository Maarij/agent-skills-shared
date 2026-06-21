# Provider Adapters

This repo owns reusable skill content. Provider-specific locations are adapters.

## Canonical source

```text
C:\Git\agent-skills-shared\skills\<skill-name>
```

Edit reusable skills here.

## Codex/shared runtime

```text
~\.agents\skills\<skill-name>
```

Installed as a junction to the canonical source.

## Claude runtime

```text
~\.claude\skills\<skill-name>
```

Installed as a junction to the Codex/shared runtime path. This preserves Claude skill-name invocation such as `/prd {text}` while keeping one canonical skill source.

## Project-local skills

Repo-specific skills should stay with the repo they describe. For example, RetireRatio's `finance-audit` skill remains in:

```text
C:\Git\retireratio\.claude\skills\finance-audit
```

Do not add project-local skills to `skills.manifest.json` unless they are intentionally promoted to reusable shared skills.
