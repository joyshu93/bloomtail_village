# Development Setup

## Engine Assumption
- Godot 4.x
- GDScript only
- 2D top-down presentation

## Recommended Project Layout
- `res://scenes/` for scenes
- `res://scripts/` for logic
- `res://resources/` for data assets
- `res://art/` for placeholder and final art
- `res://saves/` for local save data

## Reading Order Before Work
1. `AGENTS.md`
2. `specs/gameplay.md`
3. `specs/system.md`
4. `specs/balance.md`
5. `specs/art-direction.md`

## Practical Rules
- Keep each manager focused on one responsibility.
- Prefer Resource-based data for buildings, residents, and decor.
- Make default content usable without needing custom art.
