# Deploy to Cloudflare Pages (via Wrangler CLI)

This project builds into a static SPA in `dist/` and can be deployed to Cloudflare Pages with full functionality (local storage + print-to-PDF).

## Prerequisites
- Cloudflare account with a Pages project (will be created on first deploy if needed)
- Node 16.18+ locally (for build) or Docker
- Wrangler CLI installed and logged in:

```bash
npm install -g wrangler
wrangler login
```

## 1) Build the app

You can build with Node locally or alternatively, using Docker.

- Local build:

```bash
npm install
npm run build
# Output: dist/
```

- Build with Docker (no local Node required):

```bash
docker build . -t serverless-invoices
```

```sh
# Copy build artifacts out of the image
# CID=$(docker create serverless-invoices)
# docker cp "$CID":/app/dist ./dist
# docker rm "$CID"
docker cp serverless-invoices:/app/dist ./dist
```

```sh
docker create --name temp-build serverless-invoices:latest
docker cp temp-build:/app/dist ./dist
docker rm temp-build
```

Optionally: test that the build works

```bash
npx serve -s dist -l 8080
#python3 -m http.server 8080 --directory dist
```

## 2) Configure SPA routing (history mode)

Vue router uses history mode. 

Add a catch-all redirect so direct links work on Pages.

Create a `_redirects` file at the project root or in `public/` before build:

```
/*  /index.html  200
```

If you place it in `public/`, it will be copied into `dist/` during build.

## 3) Deploy with Wrangler (Direct Upload)

Use Wrangler to deploy the static `dist/` directory.

- First deploy (will create the Pages project if missing):

```bash
wrangler pages deploy dist --project-name=serverless-invoices --branch=main
```
  Notes:
  - `--project-name` must be unique in your account.
  - `--branch` is used to label the deployment; use `production` or your current branch name.

- Subsequent deploys:

```bash
wrangler pages deploy dist
```

> It will deploy to something like `https://8041cf56.serverless-invoices.pages.dev/`

> > And later on available at `https://serverless-invoices.pages.dev/invoices?lang=en`

Wrangler outputs the preview and production URLs. Promote a preview in the dashboard or deploy with `--branch=production` to target the production environment directly.

## 4) Optional: GitHub integration (CI)

Instead of local deploys, you can connect the repository to Cloudflare Pages. Set the build command and output dir:
- Build command: `npm run build`
- Output directory: `dist`
- Root directory: repository root

Make sure `_redirects` is present in the published output.

## Environment and configuration
- Default storage is local (browser) as set in `src/config/app.config.js` (copied from `src/config/app.config.example.js`).
- No server-side code is required. If you later switch to `http`/`wordpress` adapters, you must host those APIs separately and configure CORS/auth.

## Verifying after deploy
- Navigate to the Pages URL (e.g., https://<your-project>.pages.dev)
- Ensure direct links like `/invoices` load (SPA fallback working)
- Test creating an invoice, exporting/importing JSON, and printing to PDF (browser print dialog)

## Troubleshooting
- 404 on hard refresh: `_redirects` missing; ensure it gets into `dist/`.
- Blank screen due to base path: if hosting under a subpath, consider setting `base_url` in `src/config/app.config.js` and rebuild.
- Mixed content on custom domains: ensure HTTPS and correct domain settings in Cloudflare.
