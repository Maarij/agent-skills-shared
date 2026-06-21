# Installation

Run these commands from `C:\Git\agent-skills-shared`.

## 1. Verify the managed skill list

Review `skills.manifest.json`. The installers only manage skills listed there.

## 2. Install Codex/shared runtime entries

Dry run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-codex-skills.ps1 -DryRun
```

Apply:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-codex-skills.ps1
```

This creates junctions:

```text
~\.agents\skills\<skill-name>
  -> C:\Git\agent-skills-shared\skills\<skill-name>
```

## 3. Install Claude entries

Dry run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-claude-skills.ps1 -DryRun
```

Apply:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-claude-skills.ps1
```

This creates junctions:

```text
~\.claude\skills\<skill-name>
  -> ~\.agents\skills\<skill-name>
```

Run the Codex/shared install first. The Claude installer expects the shared runtime entries to exist.

## Replacing existing real directories

If an existing managed skill is a real directory instead of a junction, the installer stops unless `-Force` is supplied.

With `-Force`, the installer moves the existing directory to a timestamped backup beside it, then creates the junction. Example:

```text
~\.claude\skills\prd.backup.20260617143000
```

Review dry-run output before using `-Force`.

## Verification

After installing, restart the CLI that should discover the skills.

Useful checks:

```powershell
Get-Item ~\.agents\skills\prd | Select-Object LinkType,Target
Get-Item ~\.claude\skills\prd | Select-Object LinkType,Target
```

Claude slash-style invocation such as `/prd {text}` depends on the skill directory name under `~\.claude\skills`. The Claude installer preserves that by creating a `prd` junction at that path.
