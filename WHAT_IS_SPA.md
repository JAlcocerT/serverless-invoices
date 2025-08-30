# What is a Single-Page Application (SPA)?

A Single-Page Application is a web app that loads a single HTML page and updates the UI dynamically in the browser using JavaScript, without full-page reloads.

## How it works

- Initial load fetches `index.html`, CSS, and JS bundles.
- The JavaScript app mounts into a DOM element and controls navigation and rendering.
- Client-side routing changes the URL and updates the view without requesting a new HTML page from the server.

In this project:
- Router: `src/router.js` uses Vue Router in `history` mode.
- Views are code-split and lazy-loaded (see dynamic `import()` in route components).

## Routing: hash vs history

- Hash mode: URLs like `/#/invoices`. The part after `#` isn’t sent to the server, so servers don’t need special config.
- History mode (used here): clean URLs like `/invoices`. Requires the server to always serve `index.html` for unknown paths so the client router can take over.

## Why SPAs?

- Pros
  - Smooth navigation (no full reloads)
  - Rich interactivity with client-side state
  - Can be deployed as a static site (CDN-friendly)
- Cons
  - Requires routing fallback on static hosts (history mode)
  - Larger initial JS download vs. multi-page apps
  - SEO needs attention (though modern SPA frameworks and prerendering help)

## Relevance to this repository

- After `npm run build`, this app is a static SPA served from `dist/`.
- Data is stored in the browser (IndexedDB via LocalForage), so no backend is required by default.
- Printing to PDF is handled by the browser (`window.print()`), not a server.

## Local testing of a built SPA

Use a dev server that supports SPA fallback:
```bash
npx serve -s dist -l 8080
```
This serves `index.html` for unknown routes, matching Cloudflare Pages behavior when configured.

## Hosting an SPA (Cloudflare Pages)

Because of history mode, configure a catch-all rewrite to `index.html` so deep links work:
```
/*  /index.html  200
```
Place this in a `_redirects` file included in your published output (e.g., in `public/` so it lands in `dist/`).

## Open-source SPA frameworks and libraries

- React
- **Vue.js**
- Angular
- Svelte
- Preact
- SolidJS
- Ember.js

These are client-side UI frameworks commonly used to build SPAs. They manage state, routing (with companion routers), and view rendering in the browser.

## SPAs and Static Site Generators (SSG)

- What SSGs do: pre-render pages at build time into static HTML, CSS, and JS. Examples: Next.js (SSG mode), Nuxt (SSG/static), SvelteKit (SSG), Gatsby, Astro, Eleventy, Hugo, Jekyll.

- SPA vs SSG:
  - SPA (this project): content is rendered in the browser at runtime. Build output is static assets, but HTML for routes is not pre-rendered. Requires SPA fallback for routing.
  - SSG: HTML for routes is generated at build time; each route has a static HTML file, improving first-load and SEO. Client-side JS hydrates for interactivity.

- Hybrids: Modern meta-frameworks (Next.js, Nuxt, SvelteKit, Astro) support mixing SSG, SSR, and SPA hydration. You can pre-render some routes and keep others fully client-side.

In this repository, the Vue app is a classic SPA: it does not pre-render routes at build time; it ships a single `index.html` plus JS/CSS bundles and runs entirely in the browser.
