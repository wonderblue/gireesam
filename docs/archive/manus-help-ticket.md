# Manus Help Ticket: `storage_not_configured` During Game Publication

## Subject

Managed project storage is not configured; unable to publish Godot game

## Message

Hello Manus Help,

I am trying to publish a Godot Web game project, but the managed release process fails while uploading project assets. The release checkpoint is not created, so publication cannot proceed.

### Project details

- **Project ID:** `wdp_d61844ca16a3a65c30bfb894`
- **Project type:** Godot 2D game
- **Frontend:** Static Godot Web export
- **Backend:** Node.js API in `server/Dockerfile`
- **Database:** Enabled
- **Static build contract:** `command: true`, output directory: `site`
- **Routes:**
  - `/api/*` → server
  - `/*` → static

### Exact failure

The release process stops while uploading this asset:

```text
assets/audio/creditor_pursuit.mp3
```

The release output is:

```text
Game save did not complete. Inspect preparation and local Git before retrying. No push, checkpoint, or publication was performed.
```

The supported asset synchronization diagnostic returns:

```json
{
  "ok": false,
  "code": "storage_not_configured",
  "message": "Project storage is not configured",
  "recovery": "Activate the current project runtime environment with a complete MANUS_API_URL/MANUS_API_KEY or BUILT_IN_FORGE_API_URL/BUILT_IN_FORGE_API_KEY pair, then retry."
}
```

The project configuration reports that the server and database are enabled, but the storage upload path is unavailable.

### Requested assistance

Please check and repair the following for project `wdp_d61844ca16a3a65c30bfb894`:

1. Whether managed object storage is provisioned for the project.
2. Whether the active project runtime has the required storage-upload configuration.
3. Whether the presigned project-storage upload service is enabled.
4. Whether the Sandbox/runtime needs to be refreshed after storage provisioning.
5. Whether the project can be marked ready for release asset synchronization.

After the storage issue is repaired, I will retry the release checkpoint and publication workflow.

### Security note

I have not included any credentials or secret values. Please let me know if you need any project-side diagnostic identifiers or logs that can be safely shared.

Thank you.
