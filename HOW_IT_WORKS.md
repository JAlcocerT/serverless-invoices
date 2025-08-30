# Serverless Invoices – How it works

## Overview

- Client-side, single-page application built with Vue 2 + Bootstrap.
- No backend required by default. All data is stored in the browser.
- Docker image only serves the built static site with `http-server`.

## Architecture

- Entry: `src/main.js` mounts the SPA and sets up router/i18n/store.
- Router: `src/router.js` uses HTML5 history mode and lazy-loaded routes.
- Data access layer: `src/services/data.service.js` selects an adapter by `config.storageType`.
  - Default: `'local'` adapter (browser storage via LocalForage/IndexedDB).
  - Optional: `'http'` or `'wordpress'` adapters (you would need to provide endpoints/plugins and CORS).
- Local storage setup: `src/config/local-storage.config.js` configures LocalForage with DB name `serverlessInvoices`.

## Data storage model (default)

- Persisted entirely in the browser (IndexedDB via LocalForage).
- Keys are written/read by the store modules, e.g. `src/store/data.js`.
- Import/Export:
  - Export: `data/exportJson` reads all LocalForage keys and triggers a download `serverless-invoices.json`.
  - Import: `data/importJson` parses a selected JSON file and writes all keys back to LocalForage.
  - UI: In `src/views/dashboard/Invoices.vue`, the three-dots menu shows Export/Import when `storageType === 'local'`.

## Build and static hosting

- Build: `npm run build` produces a static `dist/` folder.
- Docker: `Dockerfile` builds the app and serves `dist/` with `http-server` on port 8080.
- The application is a **pure static SPA after build** (no server rendering, no server APIs in default mode).

## Cloudflare Pages hosting

It can be hosted on Cloudflare Pages with full functionality in default (local) storage mode.
- Deploy the `dist/` folder.
- Ensure SPA routing fallback (history mode): enable “SPA” option or add a catch-all redirect to `/index.html`.
- Example `_redirects` file in the project root (or in `public/` during build):
```
/*    /index.html   200
```
- No server-side features are required for default usage (create/edit invoices, import/export, print to PDF).
- If you switch to `'http'` or `'wordpress'` storage types, you must provide and host those backends separately and handle CORS/auth.

## Runtime configuration

- `src/config/app.config.example.js` is copied to `src/config/app.config.js` at build time (see `Dockerfile`).
- Defaults:
  - `storageType: 'local'`
  - `base_url` is empty by default; router runs in history mode. On static hosts use SPA fallback as above.

## Printing to PDF (how it works)

- There is **no server-side PDF rendering**. The app relies on the browser’s print-to-PDF.
- In `src/components/invoices/InvoiceControls.vue`, the "Download PDF" option calls `window.print()`.
- Print-friendly styles are provided (e.g., `src/assets/scss/components/_invoice.scss`) and the dedicated print view `src/views/InvoicePrint.vue` renders the invoice for printing.
- Users select “Save as PDF” in the browser’s print dialog.

## Limitations and notes

- Data is scoped per-origin (protocol + host + port). Clearing browser storage removes app data.
- To migrate data between browsers/devices, use Export/Import JSON.
- For custom domains/paths, consider setting `base_url` accordingly and ensure the SPA fallback is configured.

## Quick start

- Local via Docker: `make up` then open http://localhost:80
- Local dev: Node 16.18, `npm install`, `npm run serve`
- Export/Import: In Invoices view, use the three-dots menu (visible when using local storage).
