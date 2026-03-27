# Systems Specification

## Grid

- 24 by 24 cells
- Single-cell placeables for MVP
- Separate logical layers for ground, road, buildings, and decor

## Roads and activation

- Roads can be placed anywhere inside bounds
- Buildings requiring roads become active if orthogonally adjacent to any road
- Decorations never require roads

## Economy

- Placement subtracts cost immediately
- Active commercial and public village content contributes daily income or bonuses
- Economy updates once per in-game day

## Residents

- Each occupied house hosts one resident
- Max 8 residents
- Resident data includes name, species, personality, preferred environment tag, happiness, current line, and request state
- Happiness shifts based on nearby decor or preferred placeables around the resident's home

## Town score

Four tracked stats:

- Coziness
- Nature
- Convenience
- Atmosphere

Each placeable contributes fixed score values. Resident happiness can add a small modifier.

## Persistence

- Save one main slot to `user://cozy_village_save.json`
- Persist calendar, speed, money, placed content, residents, and score state

## Simplicity guardrails

- No production chains
- No utilities
- No traffic simulation
- No procedural map generation
- No complex pathfinding requirement for MVP
