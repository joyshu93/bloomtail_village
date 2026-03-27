# CityGame

Godot 4 + GDScript 3D vertical slice for a cozy village builder.

## Current goal

This branch proves one thing: 3D grid placement works reliably.

It is not the full simulation. The focus is a Camera3D-based prototype where the player can select a placeable, hover the ground, see a preview, and click to place a snapped 3D object.

## Run

1. Open the project in Godot 4.
2. Run `res://scenes/main/Main.tscn`.

## Controls

- `WASD` or arrow keys: move camera
- Mouse wheel: zoom camera
- Left UI buttons: choose `Road`, `House`, `Cafe`, or `Tree`
- Left click on the ground: place selected item
- Hold left mouse with `Road` selected: drag to paint roads

## Included in this branch

- `Main`, `World3D`, `UIRoot`, `Managers`
- `Node3D` + `Camera3D`
- Flat build grid with stronger hover-cell feedback
- Ghost preview with valid / blocked / inactive states
- Grid-snapped placement
- Duplicate placement blocking
- Road drag placement
- Road-adjacent active / inactive visuals for `House` and `Cafe`

## Current limits

- Placeholder primitive meshes only
- No residents
- No save/load
- No economy or scoring
- No quests or seasonal systems
- UI is still intentionally minimal and placeholder-driven
