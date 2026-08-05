// Bolt Framework — Penpot design-token export config
// Tool: @penpot-export/cli  (npm i -D @penpot-export/cli)
// Run:  npm run tokens:export   (see package.json script below)
//
// Exports Penpot colors + typography into CSS custom properties consumed by
// Tailwind v4 `@theme`, writing to the same `tokens.css` that bolt-ux-design uses.
// The REST token API is not yet shipped (penpot#7916) — this CLI is the pipeline.
//
// PREREQUISITES:
//   - A reachable Penpot instance (self-hosted via Podman or remote).
//   - A Penpot access token (Account → Access tokens) exported as PENPOT_ACCESS_TOKEN.
//   - The file id + page name(s) you want to export (from the file URL in Penpot).
//
// Provisioned by the `frontend` scope when decisions.frontend.design-tool != none.
// See: docs/integrations/penpot-integration-plan.md

/** @type {import('@penpot-export/cli').Config} */
module.exports = {
  // Self-hosted default; override for a remote/corporate instance.
  instance: process.env.PENPOT_INSTANCE || 'http://localhost:9001',
  accessToken: process.env.PENPOT_ACCESS_TOKEN, // never hard-code — read from env

  files: [
    {
      // Replace with your Penpot file id (from the file URL).
      fileId: process.env.PENPOT_FILE_ID || '<your-penpot-file-id>',
      colors: [
        {
          // CSS custom properties → consumed by Tailwind v4 `@theme` in your app CSS.
          output: 'design/tokens.css',
        },
      ],
      typographies: [
        {
          output: 'design/tokens.css',
        },
      ],
    },
  ],
};

// ── package.json wiring (add manually) ──────────────────────────────────────
//   "scripts": {
//     "tokens:export": "penpot-export"
//   }
//
// ── Tailwind v4 consumption (app CSS) ───────────────────────────────────────
//   @import "tailwindcss";
//   @import "./tokens.css";        /* generated custom properties */
//   @theme {
//     --color-brand: var(--brand);  /* map exported tokens into the theme */
//   }
