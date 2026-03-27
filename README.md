# CityGame

Godot 4 + GDScript cozy village-building MVP. The project focuses on a small 24x24 town where animal residents move in, react to their surroundings, and nudge the player toward a cute and comfortable layout.

## Run

1. Open the folder in Godot 4.
2. Run the main scene: `res://scenes/main/Main.tscn`.
3. The project starts directly in the playable village screen.

## Controls

- Left click: place selected item or select a tile / resident
- Right click or `Esc`: cancel build mode
- `Space`: pause / resume
- Top bar speed buttons: pause, 1x, 2x, 4x
- Left build menu: choose road, building, decor, or remove mode
- Right panel: inspect current tile, building, or resident
- `Village Report`: open the town score summary for coziness, nature, convenience, and atmosphere
- `Save / Settings`: save or load the village

## Current MVP features

- 24x24 tile village map
- Place roads, houses, cafe, general store, workshop, plaza, and simple decor
- Road-connected building activation
- Up to 8 animal residents with personalities, preferences, and simple requests
- Daily money, happiness, and town score updates
- Save and load from one local slot
- Notifications for move-ins, requests, and environmental improvements

## Current limits

- Placeholder art only
- Single-cell buildings and decor only
- Residents are represented as simple markers
- No pathfinding, animations, or advanced AI routines
- One save slot
- No main menu flow yet; the settings popup exposes the button as a placeholder

## Suggested next work

1. Replace placeholder rendering with proper tiles and sprites.
2. Add more resident request variety and short roaming behavior.
3. Improve building placement UX with drag roads and richer hover feedback.
4. Add a title screen, multiple saves, and audio content.
