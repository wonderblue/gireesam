# Gireesam's Great Escape — Local Export

This folder contains two packages:

1. **Web export** — a ready-to-host static Godot Web build.
2. **Source archive** — the complete project code, game assets, backend, migrations, and configuration.

## Host the Web export locally

Extract the Web export package, change into the extracted folder, and run:

```bash
python3 -m http.server 8080 --bind 0.0.0.0
```

Then open:

```text
http://localhost:8080/
```

Use a static web server rather than opening `index.html` directly with `file://`, because browsers commonly block WebAssembly and game asset requests from local files.

## Host the Web export on a static service

Upload the **contents** of the Web export folder—not the folder itself if the host expects a document root. The directory must contain `index.html`, `index.js`, `index.wasm`, `index.pck`, and the related audio/worklet and license files.

The game is a client-side Godot Web export. It does not require Node.js for the static game itself.

## Important backend note

The source archive includes the account/cloud-save backend under `server/`. The static Web export can run offline, but cross-device accounts and cloud saves require deploying the backend with:

- A managed or self-hosted MySQL-compatible database
- `DATABASE_URL`
- The Manus authentication/runtime environment variables
- The API routes configured so `/api/*` reaches the backend

The backend Dockerfile runs database migrations before starting the API. Do not expose database credentials in frontend files or commit them to source control.

## Packages generated

- `gireesam-web-export.zip` — static playable Web export
- `gireesam-source-code-and-assets.zip` — complete source and assets

Generated locally from the current project state while managed project storage remains unavailable.
