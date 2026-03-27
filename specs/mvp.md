# MVP Scope

## Branch note

The `feature/3d-vertical-slice` branch intentionally narrows this scope to a 3D click-to-place prototype with a very shallow money/day loop. The older 2D top-down UI contract, residents, saving, and the fuller economy loop are still deferred.

## Required loop

1. Start a new village on a 24x24 grid.
2. Place roads, buildings, and decorations.
3. Spend money when placing content.
4. Buildings activate only when connected to roads.
5. Time passes with pause, 2x, and 4x speed.
6. Daily economy, happiness, and town score update.
7. Residents move in up to a cap of 8 based on available homes.
8. Residents expose basic personality, preferences, and at least one simple request type.
9. The player can save and load progress.

## Starting content

Buildings:

- Resident House
- Cafe
- General Store
- Workshop
- Plaza

Decor:

- Flower
- Tree
- Bench
- Fence
- Street Lamp

## UI contract

- Main play screen does almost everything
- Left build menu
- Top resource bar
- Right info panel
- Bottom notification strip
- Resident detail popup
- Town evaluation popup
- Save/settings popup
