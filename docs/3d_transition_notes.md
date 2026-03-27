# 3D Transition Notes

This branch intentionally does not follow the old 2D MVP contract.

Conflicts with the older docs/specs:

- Ignore the 2D scene contract built around `Game`, `TileMapGround`, `TileMapRoad`, `TileMapBuildings`, `TileMapDecor`, and `Residents`.
- Ignore `Camera2D`, `Node2D`, and custom 2D draw-based placement/input.
- Ignore resident, economy, score, save/load, popup-heavy UI, and day-cycle scope for this step.
- Ignore the prior requirement that the main screen expose the full simulation loop.

What this branch does instead:

- Uses `Main`, `World3D`, `UIRoot`, and `Managers`.
- Uses `Node3D` and `Camera3D` only.
- Focuses only on a playable 3D placement prototype.
- Proves ray/plane hover, ghost preview, click placement, duplicate blocking, and road-adjacent activation.
