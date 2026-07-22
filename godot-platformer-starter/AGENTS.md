# Godot starter instructions

- GitHub Issue #8 is the source of truth for the M6 six-zone graybox; merged PR #9 is the accepted M0–M5 baseline.
- Godot 4 and GDScript are the only runtime engine and language stack.
- `game/core` contains scene-independent `RefCounted` rules and may not access Nodes, SceneTree, Input, files, resources, or physics queries.
- Dependency direction is `presentation -> runtime -> core`.
- Gameplay values live in versioned JSON under `game/content`, not in scene Nodes.
- Runtime dependencies are injected explicitly; do not use Autoloads or groups as service locators.
- Keep all four machine-readable suites plus strict import and headless startup passing.
- M7 and later work, final art, production VFX, and movement-threshold changes are out of scope for the Issue #8 branch.
