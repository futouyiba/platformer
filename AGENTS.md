# ChatGPT project context

This directory is a local mirror of the ChatGPT project “platformer”.

- Treat every file under `sources/` as read-only reference material.
- Do not edit, rename, move, or delete synced project files.
- These files may be replaced the next time a task is created from this ChatGPT project.

## Project instructions

This project has no additional product-specific instructions.

## Repository coordination

- Use GitHub Issues and the repository Project as the source of truth for mutable task status, ownership, dependencies, and acceptance criteria.
- Read the linked issue and these repository instructions before making changes. Do not expand scope silently; record independently deliverable follow-up work as a separate issue.
- Use one dedicated branch and pull request for each independently mergeable issue. Link the issue from the pull request.
- Keep commits reviewable, run the validation named in the issue, and report exact results and relevant evidence.
- Do not merge while required checks fail or dependencies remain unresolved. Use an independent reviewer when risk or scope warrants it.
- Treat files under `sources/` as read-only reference material, including from branches and worktrees.

### Task-system cutover

- GitHub became the mutable task source of truth on 2026-07-23.
- M0–M5 were reported complete and validated in the legacy Codex task `019f8a70-0564-7b71-b238-a755a5451f54`, but a later workspace rebuild removed their implementation files.
- Treat the migrated M0–M5 Issues as historical records, not proof that their code still exists in the current checkout.
- Active work must first restore or reconstruct the missing implementation and validate it before continuing with M6.
