# Godot starter instructions

- GitHub Issue #7 is the recovery source of truth for M0–M5.
- Godot 4 and GDScript are the only runtime engine and language stack.
- `game/core` contains scene-independent `RefCounted` rules and may not access Nodes, SceneTree, Input, files, resources, or physics queries.
- Dependency direction is `presentation -> runtime -> core`.
- Gameplay values live in versioned JSON under `game/content`, not in scene Nodes.
- Runtime dependencies are injected explicitly; do not use Autoloads or groups as service locators.
- Keep all four headless entries passing and emitting machine-readable JSON.
- M6 and later work are out of scope for the Issue #7 branch.
