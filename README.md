# Ashfall Frontier

A playable 2D open-world platform RPG prototype built with Godot 4.

Open `project.godot` in Godot 4.4+ and press **F5**, or run `godot --path .`.

Controls: **A/D** move, **Space/W** jump, **LMB/J** attack, **E** interact, **1/2** switch weapons, and **Q** use a health tonic.

The current vertical slice includes:

- Three connected regions with platforming routes and free-roam exploration
- A three-part story mission with an NPC quest giver and objective tracking
- Blade and unlockable pistol combat, projectiles, hit reactions, and enemy AI
- Salvage and potion pickups, health, death/respawn, XP, and leveling
- A permanent end-of-story checkpoint and post-mission free-roam state

## Adding environment artwork

Drop cloud images into `assets/environment/clouds` and distant building images into `assets/environment/buildings`. Supported formats are PNG, WebP, JPEG, and SVG. The environment loader discovers them automatically; when a folder is empty, layered procedural silhouettes are used instead.

Platform artwork belongs in `assets/environment/platforms`. See the README inside that folder for the one-line loading example. Four procedural platform materials—grass, stone, rust, and crystal—are already assigned across the regions.
