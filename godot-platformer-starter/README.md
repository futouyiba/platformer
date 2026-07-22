# Godot Platformer Starter

Recovered Godot 4 / GDScript Gate 1 implementation through M5 for [Issue #7](https://github.com/futouyiba/platformer/issues/7). The project is isolated from other prototypes and keeps gameplay rules in scene-independent `RefCounted` Core classes.

## Included

- M0: 390×844 project, layered directories, versioned JSON, content validation, four headless entries.
- M1: normalized pointer samples and deterministic move/jump/dash/fast-fall intent classification.
- M2: explicit mutually exclusive movement states with seven-tick coyote time, buffering, double jump, committed dash, fast fall, and wall slide.
- M3: Ground/Wall/Ceiling probes, swept dash-hit query, per-action target deduplication, and safe respawn.
- M4: DamagePacket, mass-scaled knockback, stun, death, duplicate-action rejection, and training enemies.
- M5: centralized Blade Talisman, Wind Ring, and Starfall Seal trigger resolution.

M6 six-zone layout work is intentionally excluded and remains tracked by Issue #8.

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
