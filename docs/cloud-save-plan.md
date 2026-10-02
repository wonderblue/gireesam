# Gireesam Account and Cloud-Save Plan

## Outcome

Add optional Manus account login and durable, cross-device player data to the existing Godot game while preserving the current offline run loop. A player may start and finish a run without signing in; signing in enables profile and progress synchronization.

## Product behavior

- The title screen shows the current local profile and an Account action with honest states: signed out, signing in, signed in, syncing, synced, or unavailable.
- Login uses Manus OAuth through the packaged `ManusAuth` browser bridge. No custom passwords, password storage, client-selected user IDs, or parallel OAuth implementation.
- A signed-in player can save and restore: display name/profile, highest completed stage, total reform-fund coins, reputation summary, tutorial state, best score, best escape time, and a bounded recent run-history list.
- Local play remains usable when the account service or database is unavailable. Offline local data remains in `user://save.json`; cloud sync failures are visible and non-destructive.
- Cloud ownership is derived only from the authenticated server session. Client payloads contain gameplay data, never an owner ID.
- Sync uses protected tRPC procedures: read the current cloud profile, merge local progress conservatively, and record a completed run idempotently.

## Architecture

- **Client:** Godot gameplay remains authoritative for offline simulation. `scripts/manus_auth.gd` exposes login/logout/session state and the browser bridge. A new `scripts/cloud_profile.gd` adapter serializes safe save data and invokes authenticated browser tRPC calls through the bridge when Web export is online.
- **Browser shell:** the installed auth bootstrap stays in `web/loading.html`, awaiting `ManusAuth.prepare()` before starting the engine and preserving the existing loading/retry UI.
- **Server:** the installed Webdev auth adapter owns OAuth callbacks, session validation, and the canonical `users` table. `server/routers.mjs` adds protected profile/progress/run procedures, with `server/db.mjs` owning the game repository.
- **Database:** additive MySQL-compatible migration creates one profile row per authenticated user and a bounded run-history table with unique `(user_id, run_id)`. No destructive migration or seed data.
- **Delivery:** keep Godot's `true` → `site` build. Publish a hybrid deployment with `/api/*` routed to the server and all other paths to static game files. `/api/health` is unauthenticated; personalized API responses are `no-store`.

## Data model and safety

- `game_profiles`: integer Webdev user key, display name, highest stage, total coins, reputation, best score, best duration, tutorial version, timestamps.
- `game_run_records`: integer user key, opaque run ID, stage, outcome, score, duration, timestamp, eligible flag, configuration hash; unique per owner/run ID and bounded per account.
- Server validates lengths, numeric bounds, allowed outcomes, configuration shape, and run ID format. It derives ownership from `ctx.user.id` and never accepts a user ID from the client.
- Merge policy is monotonic for progress and bests; newer profile text can update display name; run history is idempotent and capped server-side.

## Verification and delivery

- Run existing Godot import, boot, gameplay, audio, and contract checks.
- Run server syntax/tests and migration validation against the managed project database using the supported workflow.
- Verify the saved online checkpoint, not the resident Preview, for login/session, profile readback, cloud save, reload continuity, logout, and offline fallback. Browser acceptance remains pending until a real account signs in through the published/online checkpoint.
- Save a matching hybrid release, run the pack check, and publish only after the checkpoint is registered.

## Constraints

- The game UI is English for readability, while the original Telugu voice/audio flavor and offline gameplay remain unchanged.
- No public leaderboard is added; personal game records are account data, not shared rankings.
- No secrets, OAuth codes, cookies, or database URLs enter GDScript, client assets, logs, or Git.
