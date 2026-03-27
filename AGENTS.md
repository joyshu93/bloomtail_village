# Development Operating Rules

This repository is built with Codex subagents. Every substantial task should assign at least:

- `architect`: scene tree, data flow, manager boundaries, save/load review
- `gameplay`: mechanics, balancing, resident behavior, placement flow
- `docs`: specs, README, operating notes, change logs

Core rules:

1. Read [docs/vision.md](./docs/vision.md), [docs/project-overview.md](./docs/project-overview.md), [docs/dev-setup.md](./docs/dev-setup.md), [specs/mvp.md](./specs/mvp.md), and [specs/systems.md](./specs/systems.md) before changing gameplay code.
2. Keep the Godot 4 + GDScript MVP playable at all times. Favor simple working structure over clever abstractions.
3. Preserve the requested scene contract:
   `Main`, `Game`, `UIRoot`, `Managers`, `TileMapGround`, `TileMapRoad`, `TileMapBuildings`, `TileMapDecor`, `Residents`.
4. Prefer data-driven placeables and resident templates. New content should be added through `resources/` first.
5. Save data must remain forward-readable JSON stored in `user://cozy_village_save.json`.
6. Do not introduce plugins, C#, addons, or external dependencies without explicit approval.
7. Keep graphics placeholder-friendly. Simple colors and shapes are acceptable if the loop stays playable.
8. Before merging substantial changes, sanity-check:
   placement, economy tick, resident happiness, score recalculation, save/load, and UI refresh.
9. When a change affects design intent, update the relevant file in `docs/` or `specs/`.
10. Never remove user-created files or overwrite unrelated work.
