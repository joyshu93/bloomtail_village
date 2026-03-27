# System Spec

## Core Managers
- `GameManager`: time flow, pause, speed, global loop state.
- `BuildManager`: placement mode, validation, cost handling, activation checks.
- `EconomyManager`: money balance, income and upkeep.
- `ResidentManager`: resident generation, move-in rules, happiness updates, requests.
- `TownScoreManager`: comfort, nature, convenience, and atmosphere scores.
- `SaveManager`: save and load game state.

## Data Model
Use Resource-driven data for:
- Buildings
- Decor
- Residents

Suggested fields:
- `id`
- `name`
- `category`
- `cost`
- `icon`
- `tile_id`
- `score_effects`
- `connection_rules`

## Scene Structure
- `Main`
- `Game`
- `UIRoot`
- `Managers`
- `TileMapGround`
- `TileMapRoad`
- `TileMapBuildings`
- `TileMapDecor`
- `Residents`

## Save State
Persist enough state to restore:
- Map placements
- Money
- Time and season
- Resident roster
- Happiness and request status

## Constraints
- No complex logistics systems.
- No deep AI or production simulation.
- No dependence on high-end art to make the MVP functional.
