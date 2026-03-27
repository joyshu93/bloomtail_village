# Gameplay Spec

## Map
- Grid size: 24x24 tiles.
- Top-down view only.
- Core tile layers: ground, roads, buildings, decor.

## Build Categories
- Roads
- Housing
- Shops
- Public buildings
- Decor

## First Build Set
- Housing: resident house
- Shops: cafe, general store, workshop
- Public: plaza
- Decor: flower, tree, bench, fence, street lamp

## Placement Rules
- Buildings and decor can be placed on valid tiles only.
- Buildings require road connection to become active.
- The UI must clearly show whether a placed item is active, blocked, or pending connection.

## Residents
- Maximum active residents: 8.
- Each resident has a name, animal type, personality, preferred environment, happiness, and a simple request.
- Happiness should change gradually based on nearby town conditions.

## Requests
- At least one simple request loop must exist.
- Example request types:
  - Place flowers near a house
  - Add a bench
  - Improve the area around a cafe

## Player Feedback
- Top bar should show money, resident count, happiness, and season/date.
- The right panel should show selected tile or building details.
- Notifications should communicate small local changes and resident reactions.
