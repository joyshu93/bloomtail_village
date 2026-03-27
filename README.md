# CityGame

Godot 4 + GDScript 3D vertical slice for a cozy village builder.

## Current goal

This branch proves one thing: 3D grid placement works reliably, with a very shallow operating loop layered on top.

It is not the full simulation. The focus is a Camera3D-based prototype where the player can select a placeable, hover the ground, see a preview, and click to place a snapped 3D object.

## Run

1. Open the project in Godot 4.
2. Run `res://scenes/main/Main.tscn`.

## Controls

- `WASD` or arrow keys: move camera
- Mouse wheel: zoom camera
- Left UI buttons: choose `Road`, `House`, `Cafe`, `Tree`, or `Remove`
- Left click on the ground: place selected item
- Hold left mouse with `Road` selected: drag to paint roads
- With `Remove` selected, left click a placed object to clear that cell

## Minimal loop

- Start with `500` funds
- `Road`, `House`, `Cafe`, and `Tree` all cost money to place, and the cost is actually deducted on successful placement
- If funds are too low, placement is blocked
- A new day passes automatically every few seconds
- Active `House` tiles add to the village count
- Active `Cafe` tiles earn coins each day
- Inactive `House` and `Cafe` tiles do not contribute until a road touches them
- `Remove` clears a tile but does not refund money
- A few simple residents can move into active houses and react to roads, trees, and cafes

## Included in this branch

- `Main`, `World3D`, `UIRoot`, `Managers`
- `Node3D` + `Camera3D`
- Flat build grid with clearer hover-cell and state feedback
- Ghost preview with valid / blocked / inactive / remove-target states
- Grid-snapped placement
- Duplicate placement blocking
- Road drag placement
- Remove tool
- Starting funds, day progression, and a minimal active-building economy loop
- A first resident reaction layer with simple happiness states and one-line comments
- Road-adjacent active / inactive visuals for `House` and `Cafe`
- Tighter camera movement and zoom limits for the build area

## Current limits

- Placeholder primitive meshes only
- No moving resident characters in the 3D world
- No save/load
- No deep economy or scoring
- No quests or seasonal systems
- UI is still intentionally minimal and placeholder-driven
