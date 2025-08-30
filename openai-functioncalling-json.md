# Generate importable JSON via OpenAI Function Calling (local-only)

This doc shows how to locally generate a valid Serverless Invoices import JSON from natural language using OpenAI function calling. No app changes required.

- Reference JSON: `serverless-invoices-example.json`
- Import/Export logic: `src/store/data.js` (e.g., `importJson()`)
- Goal: produce `serverless-invoices.json` and import via the app UI (Invoices → Import)

## Overview

1) Define a strict JSON Schema that mirrors the import payload (company, clients, invoices, etc.).
2) Use OpenAI function calling (tools) to force the model to return exactly that schema.
3) Validate the result with AJV and write `serverless-invoices.json` locally.
4) Import the file via the UI.

Keep your API key local; run via Node.js (do not use browser calls).

## Quick start

Create a separate folder (optional) and install deps:

```bash
npm init -y
npm i openai ajv ajv-formats
```

Set your key:

```bash
export OPENAI_API_KEY=sk-...
```

## schema.json (example skeleton)

Adjust fields to match your needs; start from `serverless-invoices-example.json`.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ServerlessInvoicesImport",
  "type": "object",
  "properties": {
    "company": {
      "type": "object",
      "properties": {
        "name": { "type": "string" },
        "address": { "type": "string" },
        "email": { "type": "string" },
        "taxId": { "type": "string" }
      },
      "required": ["name"]
    },
    "clients": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": { "type": "string" },
          "name": { "type": "string" },
          "email": { "type": "string" },
          "address": { "type": "string" }
        },
        "required": ["id", "name"]
      }
    },
    "invoices": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": { "type": "string" },
          "clientId": { "type": "string" },
          "issueDate": { "type": "string" },
          "dueDate": { "type": "string" },
          "currency": { "type": "string" },
          "items": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "description": { "type": "string" },
                "quantity": { "type": "number" },
                "unitPrice": { "type": "number" },
                "taxRate": { "type": "number", "default": 0 }
              },
              "required": ["description", "quantity", "unitPrice"]
            }
          },
          "notes": { "type": "string" },
          "status": {
            "type": "string",
            "enum": ["draft", "sent", "paid", "overdue"],
            "default": "draft"
          }
        },
        "required": ["id", "clientId", "items"]
      }
    },
    "bankAccounts": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "bankName": { "type": "string" },
          "iban": { "type": "string" },
          "swift": { "type": "string" }
        }
      }
    }
  },
  "required": ["company", "clients", "invoices"]
}
```

## generate.js (local tool-calling + validation)

```js
import fs from 'node:fs';
import path from 'node:path';
import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import OpenAI from 'openai';

const ajv = new Ajv({ allErrors: true, useDefaults: true });
addFormats(ajv);

const schema = JSON.parse(fs.readFileSync('./schema.json', 'utf8'));
const validate = ajv.compile(schema);

const userPrompt = process.argv.slice(2).join(' ').trim() ||
  'Create two invoices for Acme Ltd: 10h @ 120 EUR/h this month, one paid, one due in 30 days. Client email billing@acme.com. My company is Foo SRL, VAT RO123, address Some St 1, Bucharest. Currency EUR.';

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// Tool/function definition mirrors schema
const tools = [
  {
    type: 'function',
    function: {
      name: 'createInvoicesPayload',
      description: 'Produce a serverless-invoices import JSON from a natural-language request.',
      parameters: schema
    }
  }
];

const messages = [
  {
    role: 'system',
    content: 'You convert business requests into a valid serverless-invoices import JSON. Use the tool and fill reasonable defaults where missing.'
  },
  { role: 'user', content: userPrompt }
];

const res = await client.chat.completions.create({
  model: 'gpt-4o-mini',
  messages,
  tools,
  tool_choice: { type: 'function', function: { name: 'createInvoicesPayload' } }
});

const toolCall = res.choices[0]?.message?.tool_calls?.[0];
if (!toolCall?.function?.arguments) {
  console.error('No tool call returned. Full response:', JSON.stringify(res, null, 2));
  process.exit(1);
}

let payload;
try {
  payload = JSON.parse(toolCall.function.arguments);
} catch (e) {
  console.error('Failed to parse tool arguments as JSON:', e);
  process.exit(1);
}

// Fill sensible local defaults if missing
for (const inv of payload.invoices || []) {
  inv.currency ||= 'EUR';
  inv.status ||= 'draft';
}

// Basic referential integrity: ensure clients exist
const clientIds = new Set((payload.clients || []).map(c => c.id));
for (const inv of (payload.invoices || [])) {
  if (!clientIds.has(inv.clientId)) {
    const cid = inv.clientId || `client-${Math.random().toString(36).slice(2, 8)}`;
    payload.clients ||= [];
    payload.clients.push({ id: cid, name: 'Unknown Client' });
    inv.clientId = cid;
  }
}

// Validate
const ok = validate(payload);
if (!ok) {
  console.error('Schema validation errors:', validate.errors);
  process.exit(1);
}

const out = path.resolve('./serverless-invoices.json');
fs.writeFileSync(out, JSON.stringify(payload, null, 2), 'utf8');
console.log('Wrote', out);
```

## Usage

```bash
OPENAI_API_KEY=sk-... node generate.js "Create an invoice for Acme Ltd for 5h @ 100 EUR/h, due in 15 days. Company Foo SRL, VAT RO123."
```

Then import `serverless-invoices.json` via the app UI (Invoices → Import). No app code needs changing.

## Best practices

- Keep this script outside the SPA; do not expose your API key in the browser.
- Start from `serverless-invoices-example.json` to match field names precisely.
- Validate with AJV, set defaults (currency, status), and ensure `clientId` references an existing client.
- Consider versioning your schema if your import shape evolves.
