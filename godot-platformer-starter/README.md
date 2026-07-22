# Godot Platformer Starter

Godot 4 / GDScript Gate 1 movement sandbox through the M6 six-zone graybox tracked by [Issue #8](https://github.com/futouyiba/platformer/issues/8). The project is isolated from other prototypes and keeps gameplay rules in scene-independent `RefCounted` Core classes.

## Included

- M0: 390×844 project, layered directories, versioned JSON, content validation, four headless entries.
- M1: normalized pointer samples and deterministic move/jump/dash/fast-fall intent classification.
- M2: explicit mutually exclusive movement states with seven-tick coyote time, buffering, double jump, committed dash, fast fall, and wall slide.
- M3: Ground/Wall/Ceiling probes, swept dash-hit query, per-action target deduplication, and safe respawn.
- M4: DamagePacket, mass-scaled knockback, stun, death, duplicate-action rejection, and training enemies.
- M5: centralized Blade Talisman, Wind Ring, and Starfall Seal trigger resolution.
- M6: data-driven A–F graybox zones for dash, jump/double-jump, Wind Ring, fast-fall, wall-slide, and review/reset validation.

`game/content/sandbox/layout.six_zones.json` is the layout source of truth. Runtime code binds its coordinates, platforms, enemies, prompts, zone bounds, and primary validation actions into Godot nodes.

## Validation

Run from this directory with Godot 4:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tools/test_core.gd
godot --headless --path . --script res://tools/test_content.gd
godot --headless --path . --script res://tools/test_integration.gd
godot --headless --path . --script res://tools/test_scene_smoke.gd
godot --headless --path . --quit-after 3
```

Each test entry prints a single JSON report and uses its exit code for pass/fail.
