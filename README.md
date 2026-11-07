# Roblox Survival Game Script

Nightfall Escape is a Roblox survival game script for a Piggy-like escape-and-survive experience, featuring server-authoritative rounds, a Hunter role, survivor objectives, collectible keys, an unlockable exit gate, timed gameplay, catching mechanics, sprinting, and a procedurally generated arena.

## Install

1. Open Roblox Studio and create or open a place.
2. Create a normal `Script` in `ServerScriptService` named `GameServer`.
3. Copy the contents of `src/server/GameServer.server.lua` into `GameServer`.
4. Create a `LocalScript` in `StarterPlayer > StarterPlayerScripts` named `GameClient`.
5. Copy the contents of `src/client/GameClient.client.lua` into `GameClient`.
6. Press Play with at least two test players.

The server script automatically creates the arena, boundaries, cover, trees, spawn points, exit gate, key objects, prompts, RemoteEvent, and round controller.

## Use

1. Start the game with at least two players.
2. Wait through the intermission period.
3. One player is randomly assigned as the Hunter.
4. Survivors search the arena and collect three keys.
5. Survivors use the `Unlock and escape` prompt at the front gate after collecting all required keys.
6. The Hunter catches survivors by getting within close range.
7. Hold `Left Shift` during a round to sprint as a survivor.
8. Survivors win when every living survivor escapes.
9. The Hunter wins when all survivors are caught or the round timer expires.
10. Adjust round settings at the top of `src/server/GameServer.server.lua`, including intermission duration, round length, required keys, catch distance, and movement speeds.

---

More Roblox script projects by EnderDevelopment: https://github.com/EnderDevelopment

Project page: https://dash.enderdevelopment.com/community/356707b8-bc92-4688-bd55-9c67e7ba5c20?utm_source=github&utm_medium=readme&utm_campaign=auto_publish&utm_content=356707b8-bc92-4688-bd55-9c67e7ba5c20
